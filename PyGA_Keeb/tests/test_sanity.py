"""Sanity tests for the corpus analysis, fitness function, and GA (claude.md 4.5).

Run with:  python3.9 -m unittest discover -s tests -v
(from inside PyGA_Keeb/, so the project modules are importable)
"""
import random
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import corpus_analysis
import costs
import fitness
from ga_optimizer import GAConfig, run_ga


class TestCorpusAnalysis(unittest.TestCase):
    def test_counts_known_corpus(self):
        with tempfile.TemporaryDirectory() as tmp:
            corpus_file = Path(tmp) / "sample.txt"
            corpus_file.write_text("aba.aba")  # lowercase, allowed chars only
            counts = corpus_analysis.count_ngrams(Path(tmp), max_order=2)

            self.assertEqual(counts[1]["a"], 4)
            self.assertEqual(counts[1]["b"], 2)
            self.assertEqual(counts[1]["."], 1)
            # bigrams: "ab","ba","a.", then break (no bigram across '.'), ".a","ab","ba"
            self.assertEqual(counts[2]["ab"], 2)
            self.assertEqual(counts[2]["ba"], 2)
            self.assertEqual(counts[2]["a."], 1)
            self.assertEqual(counts[2][".a"], 1)
            # no bigram should cross a break introduced by a disallowed character
            with tempfile.TemporaryDirectory() as tmp2:
                f2 = Path(tmp2) / "sample2.txt"
                f2.write_text("a\nb")  # newline is a break, not an allowed char
                counts2 = corpus_analysis.count_ngrams(Path(tmp2), max_order=2)
                self.assertEqual(counts2[2].get("ab", 0), 0)

    def test_ignores_disallowed_characters(self):
        with tempfile.TemporaryDirectory() as tmp:
            corpus_file = Path(tmp) / "sample.md"
            corpus_file.write_text("# Title\nHello, World! 123")
            counts = corpus_analysis.count_ngrams(Path(tmp), max_order=1)
            # digits, '#', '!', whitespace must not be counted
            for forbidden in "#!123 \n":
                self.assertNotIn(forbidden, counts[1])


class TestFitness(unittest.TestCase):
    def setUp(self):
        # A tiny synthetic corpus: 'e' is far more frequent than 'z'.
        self.ngram_data = {
            "1": {"e": 1000, "z": 1, **{c: 1 for c in "abcdfghijklmnopqrstuvwxy.,'" + ";"}},
            "2": {},
        }

    def test_unigram_monotonic_swap(self):
        """Swapping a high-frequency letter onto an easier key should lower fitness."""
        layout = list(fitness.random_layout(random.Random(0)))
        e_pos = layout.index("e")
        # position 12 ("d" home-row key in qwerty) has effort 1 (easiest);
        # position 0 has effort 8 (hardest) -- see fitness.POSITION_EFFORT.
        easy_pos, hard_pos = 12, 0

        layout_e_easy = list(layout)
        layout_e_easy[e_pos], layout_e_easy[easy_pos] = layout_e_easy[easy_pos], layout_e_easy[e_pos]
        layout_e_hard = list(layout)
        layout_e_hard[e_pos], layout_e_hard[hard_pos] = layout_e_hard[hard_pos], layout_e_hard[e_pos]

        fit_easy = fitness.compute_fitness(tuple(layout_e_easy), self.ngram_data)
        fit_hard = fitness.compute_fitness(tuple(layout_e_hard), self.ngram_data)

        self.assertLess(fit_easy, fit_hard)

    def test_allow_swipe_motions_toggle_changes_bigram_cost(self):
        """Disabling swipes must charge the regular same-finger rate instead of the cheap swipe rate."""
        # positions 1 and 11 are same-finger, swipe-eligible (verified directly
        # against costs.bigram_cost): cheap with swipes, pricier without.
        self.assertEqual(costs.bigram_cost(1, 11, allow_swipes=True), 2.0)
        self.assertEqual(costs.bigram_cost(1, 11, allow_swipes=False), 4.0)
        self.assertEqual(costs.bigram_cost(1, 11), costs.bigram_cost(1, 11, allow_swipes=True))

    def test_allow_swipe_motions_propagates_through_compute_fitness(self):
        """The toggle must reach fitness.compute_fitness, not just costs.bigram_cost directly."""
        layout = fitness.random_layout(random.Random(0))
        ngram_data = {"1": self.ngram_data["1"], "2": {"ez": 5}}
        fit_with = fitness.compute_fitness(layout, ngram_data, allow_swipe_motions=True)
        fit_without = fitness.compute_fitness(layout, ngram_data, allow_swipe_motions=False)
        self.assertEqual(fit_with, fitness.compute_fitness(layout, ngram_data))
        self.assertGreaterEqual(fit_without, fit_with)

    def test_weight_validation_flags_negative_weight(self):
        warnings = fitness.validate_weights({1: 1.0, 2: -0.5})
        self.assertTrue(any("negative" in w for w in warnings))

    def test_weight_validation_accepts_equal_weights(self):
        warnings = fitness.validate_weights({1: 1.0, 2: 1.0, 3: 1.0})
        self.assertEqual(warnings, [])

    def test_default_weight_is_noop(self):
        """Omitting weights (or passing all-1.0) must reproduce the unweighted sum."""
        layout = fitness.random_layout(random.Random(0))
        fit_no_weights = fitness.compute_fitness(layout, self.ngram_data)
        fit_explicit_ones = fitness.compute_fitness(layout, self.ngram_data, weights={1: 1.0, 2: 1.0})
        self.assertEqual(fit_no_weights, fit_explicit_ones)


class TestGABaselineAndReproducibility(unittest.TestCase):
    def setUp(self):
        import json

        data_path = Path(__file__).resolve().parent.parent / "data" / "ngram_counts.json"
        self.ngram_data = json.loads(data_path.read_text())["counts"]
        self.top_n = {3: 500, 4: 500, 5: 500}

    def test_ga_beats_random_baseline(self):
        cfg = GAConfig(population_size=40, generations=25, seed=7)
        result = run_ga(self.ngram_data, self.top_n, cfg)

        rng = random.Random(123)
        random_fitnesses = [
            fitness.compute_fitness(fitness.random_layout(rng), self.ngram_data, top_n=self.top_n)
            for _ in range(40)
        ]
        self.assertLess(result.best_fitness, min(random_fitnesses))

    def test_reproducible_with_same_seed(self):
        cfg = GAConfig(population_size=20, generations=10, seed=99)
        result1 = run_ga(self.ngram_data, self.top_n, cfg)
        result2 = run_ga(self.ngram_data, self.top_n, cfg)
        self.assertEqual(result1.best_layout, result2.best_layout)
        self.assertEqual(result1.best_fitness, result2.best_fitness)

    def test_different_seeds_converge_to_similar_fitness(self):
        fitnesses = []
        for seed in (1, 2, 3):
            cfg = GAConfig(population_size=40, generations=40, seed=seed)
            result = run_ga(self.ngram_data, self.top_n, cfg)
            fitnesses.append(result.best_fitness)
        spread = max(fitnesses) - min(fitnesses)
        self.assertLess(spread, 0.15, f"GA results too divergent across seeds: {fitnesses}")


if __name__ == "__main__":
    unittest.main()
