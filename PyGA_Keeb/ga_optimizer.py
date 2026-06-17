"""Genetic algorithm that searches for a low-effort keyboard layout.

Custom implementation (no external GA library): population management and
operator choices follow the structural design of R LEGS (selection,
crossover, mutation, elitism) per claude.md 4.2, but the genome here is a
permutation of `keyboard.CHARACTERS` across the 30 key positions, so
crossover/mutation must preserve permutation validity (order crossover +
swap mutation), unlike R LEGS' representation.

Individuals are represented as tuples of 30 characters (a `Layout`, see
fitness.py). Fitness is *minimized* (lower = less typing effort).
"""
from __future__ import annotations

import json
import random
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from constraints import Constraint
from fitness import Layout, compute_fitness, prefilter_ngram_data, random_layout
from keyboard import CHARACTERS


@dataclass
class GAConfig:
    population_size: int = 200
    generations: int = 300
    crossover_rate: float = 0.9
    mutation_rate: float = 0.15
    elitism_count: int = 4
    tournament_size: int = 5
    seed: Optional[int] = 42
    adaptive_mutation: bool = True


@dataclass
class GenerationStats:
    generation: int
    best_fitness: float
    avg_fitness: float
    worst_fitness: float
    mutation_rate: float


@dataclass
class GAResult:
    best_layout: Layout
    best_fitness: float
    history: List[GenerationStats] = field(default_factory=list)


def _tournament_select(population: List[Layout], fitnesses: List[float], k: int, rng: random.Random) -> Layout:
    contenders = rng.sample(range(len(population)), k)
    best_idx = min(contenders, key=lambda i: fitnesses[i])
    return population[best_idx]


def _order_crossover(parent1: Layout, parent2: Layout, rng: random.Random) -> Layout:
    """Order crossover (OX): preserves a slice from parent1, fills the rest
    from parent2's relative order, guaranteeing a valid permutation."""
    n = len(parent1)
    i, j = sorted(rng.sample(range(n), 2))
    child: List[Optional[str]] = [None] * n
    child[i : j + 1] = parent1[i : j + 1]
    taken = set(child[i : j + 1])
    fill_values = [ch for ch in parent2 if ch not in taken]
    fill_positions = [p for p in range(n) if child[p] is None]
    for pos, ch in zip(fill_positions, fill_values):
        child[pos] = ch
    return tuple(child)


def _swap_mutate(layout: Layout, rate: float, rng: random.Random) -> Layout:
    layout = list(layout)
    n = len(layout)
    for pos in range(n):
        if rng.random() < rate:
            other = rng.randrange(n)
            layout[pos], layout[other] = layout[other], layout[pos]
    return tuple(layout)


def _population_diversity(population: List[Layout]) -> float:
    """Fraction of unique layouts in the population (1.0 = all distinct)."""
    return len(set(population)) / len(population)


def run_ga(
    ngram_data: Dict[str, Dict[str, int]],
    top_n: Dict[int, Optional[int]],
    config: GAConfig,
    progress_callback=None,
    constraints: Optional[List[Constraint]] = None,
    weights: Optional[Dict[int, float]] = None,
    allow_swipe_motions: bool = True,
) -> GAResult:
    rng = random.Random(config.seed)
    ngram_data = prefilter_ngram_data(ngram_data, top_n)

    population = [random_layout(rng) for _ in range(config.population_size)]
    history: List[GenerationStats] = []
    mutation_rate = config.mutation_rate

    best_layout: Optional[Layout] = None
    best_fitness = float("inf")

    for gen in range(config.generations):
        fitnesses = [
            compute_fitness(ind, ngram_data, weights, top_n, constraints, allow_swipe_motions)
            for ind in population
        ]

        gen_best_idx = min(range(len(population)), key=lambda i: fitnesses[i])
        gen_best_fitness = fitnesses[gen_best_idx]
        if gen_best_fitness < best_fitness:
            best_fitness = gen_best_fitness
            best_layout = population[gen_best_idx]

        if config.adaptive_mutation:
            diversity = _population_diversity(population)
            mutation_rate = config.mutation_rate * (2.0 if diversity < 0.3 else 1.0)

        stats = GenerationStats(
            generation=gen,
            best_fitness=gen_best_fitness,
            avg_fitness=sum(fitnesses) / len(fitnesses),
            worst_fitness=max(fitnesses),
            mutation_rate=mutation_rate,
        )
        history.append(stats)
        if progress_callback is not None:
            progress_callback(stats)

        ranked = sorted(range(len(population)), key=lambda i: fitnesses[i])
        next_population = [population[i] for i in ranked[: config.elitism_count]]

        while len(next_population) < config.population_size:
            parent1 = _tournament_select(population, fitnesses, config.tournament_size, rng)
            parent2 = _tournament_select(population, fitnesses, config.tournament_size, rng)
            if rng.random() < config.crossover_rate:
                child = _order_crossover(parent1, parent2, rng)
            else:
                child = parent1
            child = _swap_mutate(child, mutation_rate, rng)
            next_population.append(child)

        population = next_population

    assert best_layout is not None
    return GAResult(best_layout=best_layout, best_fitness=best_fitness, history=history)


def save_run(
    result: GAResult,
    output_dir: Path,
    config: GAConfig,
    run_name: Optional[str] = None,
    constraint_names: Optional[List[str]] = None,
    weights: Optional[Dict[int, float]] = None,
    allow_swipe_motions: bool = True,
) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    run_id = time.strftime("%Y%m%d-%H%M%S")
    suffix = f"-{run_name}" if run_name else ""
    run_dir = output_dir / f"run-{run_id}{suffix}"
    run_dir.mkdir(parents=True, exist_ok=True)

    layout_rows = [
        "".join(result.best_layout[r * 10 : r * 10 + 10]) for r in range(3)
    ]
    (run_dir / "best_layout.txt").write_text("\n".join(layout_rows) + "\n", encoding="utf-8")

    log = {
        "config": vars(config),
        "weights": weights or {},
        "allow_swipe_motions": allow_swipe_motions,
        "constraints": constraint_names or [],
        "best_fitness": result.best_fitness,
        "best_layout": result.best_layout,
        "history": [vars(s) for s in result.history],
    }
    (run_dir / "log.json").write_text(json.dumps(log, indent=2), encoding="utf-8")

    return run_dir


def plot_history(history: List[GenerationStats], output_path: Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    generations = [s.generation for s in history]
    best = [s.best_fitness for s in history]
    avg = [s.avg_fitness for s in history]

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(generations, best, label="best fitness")
    ax.plot(generations, avg, label="average fitness", linestyle="--")
    ax.set_xlabel("generation")
    ax.set_ylabel("fitness (lower is better)")
    ax.set_title("GA convergence")
    ax.legend()
    fig.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)


if __name__ == "__main__":
    import argparse

    import yaml

    from constraints import build_constraints

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config.yaml")
    parser.add_argument("--ngram-data", default="data/ngram_counts.json")
    parser.add_argument(
        "--run-name",
        default=None,
        help="Optional suffix for the results/run-<timestamp>-<name>/ directory.",
    )
    args = parser.parse_args()

    cfg = yaml.safe_load(Path(args.config).read_text())
    ngram_payload = json.loads(Path(args.ngram_data).read_text())

    top_n = {int(k): v for k, v in cfg["fitness"]["top_n"].items()}
    weights = {int(k): v for k, v in cfg["fitness"].get("weights", {}).items()}
    allow_swipe_motions = cfg["fitness"].get("allow_swipe_motions", True)
    ga_cfg = GAConfig(**cfg["ga"])
    constraints = build_constraints(cfg.get("constraints"))
    if constraints:
        print("Active constraints: " + ", ".join(f"{c.name} (weight={c.weight})" for c in constraints))
    if not allow_swipe_motions:
        print("Swipe motions disabled (allow_swipe_motions: false)")

    def report(stats: GenerationStats) -> None:
        if stats.generation % 10 == 0:
            print(f"gen {stats.generation:4d}  best={stats.best_fitness:.4f}  avg={stats.avg_fitness:.4f}  mut={stats.mutation_rate:.3f}")

    result = run_ga(
        ngram_payload["counts"], top_n, ga_cfg, progress_callback=report,
        constraints=constraints, weights=weights, allow_swipe_motions=allow_swipe_motions,
    )

    output_dir = Path(cfg["logging"]["output_dir"])
    run_dir = save_run(
        result, output_dir, ga_cfg,
        run_name=args.run_name,
        constraint_names=[c.name for c in constraints],
        weights=weights,
        allow_swipe_motions=allow_swipe_motions,
    )

    if cfg["visualization"]["enabled"]:
        plot_history(result.history, run_dir / "fitness_history.png")

    print(f"Best fitness: {result.best_fitness:.4f}")
    print(f"Best layout:\n" + "\n".join("".join(result.best_layout[r * 10 : r * 10 + 10]) for r in range(3)))
    print(f"Run saved to {run_dir}")
