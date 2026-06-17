"""Corpus analysis: absolute unigram / n-gram counts for the layout fitness function.

Scans every file in a corpus directory, tokenizes at the character level,
and counts absolute occurrences of unigrams through n-grams of a
configurable maximum order. Counts are derived purely from the supplied
corpus (no external frequency databases), per claude.md Section 3.3.

Tokenization rules:

* Text is lowercased (the layout only has lowercase letter keys).
* Only characters in ``keyboard.CHARACTERS`` (26 letters + ``. , ' ;``) are
  countable tokens.
* Any other character (digits, markdown syntax, whitespace, newlines, ...)
  is treated as a *break*: it ends the current run without contributing a
  token, so n-grams are never formed across word/line/markup boundaries.
  This keeps markdown source files usable as corpus input without needing
  a separate markdown stripping step.
"""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path
from typing import Dict, Iterable, List

from keyboard import CHARACTERS

ALLOWED_CHARS = set(CHARACTERS)


def _runs_of_allowed_chars(text: str) -> Iterable[str]:
    """Split text into maximal runs of consecutive allowed characters."""
    run: List[str] = []
    for ch in text.lower():
        if ch in ALLOWED_CHARS:
            run.append(ch)
        elif run:
            yield "".join(run)
            run = []
    if run:
        yield "".join(run)


def iter_corpus_files(corpus_path: Path) -> List[Path]:
    if corpus_path.is_file():
        return [corpus_path]
    return sorted(p for p in corpus_path.rglob("*") if p.is_file())


def count_ngrams(corpus_path: Path, max_order: int) -> Dict[int, Counter]:
    """Count absolute occurrences of n-grams of order 1..max_order.

    Returns a dict {order: Counter({ngram_tuple: count})}.
    """
    counts: Dict[int, Counter] = {order: Counter() for order in range(1, max_order + 1)}

    for file_path in iter_corpus_files(corpus_path):
        try:
            text = file_path.read_text(encoding="utf-8", errors="ignore")
        except (UnicodeDecodeError, OSError):
            continue
        for run in _runs_of_allowed_chars(text):
            for order in range(1, max_order + 1):
                if len(run) < order:
                    continue
                for i in range(len(run) - order + 1):
                    counts[order][run[i : i + order]] += 1

    return counts


def top_n(counter: Counter, n: int | None) -> Dict[str, int]:
    items = counter.most_common(n) if n is not None else counter.most_common()
    return {ngram: count for ngram, count in items}


def save_counts(counts: Dict[int, Counter], output_dir: Path, top_n_per_order: Dict[int, int] | None = None) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    top_n_per_order = top_n_per_order or {}

    payload = {
        "max_order": max(counts),
        "characters": list(CHARACTERS),
        "counts": {
            str(order): top_n(counter, top_n_per_order.get(order))
            for order, counter in counts.items()
        },
        "totals": {str(order): sum(counter.values()) for order, counter in counts.items()},
        "unique_ngrams": {str(order): len(counter) for order, counter in counts.items()},
    }

    out_path = output_dir / "ngram_counts.json"
    out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    return out_path


def analyze(corpus_path: str, max_order: int, output_dir: str, top_n_per_order: Dict[int, int] | None = None) -> Path:
    counts = count_ngrams(Path(corpus_path), max_order)
    return save_counts(counts, Path(output_dir), top_n_per_order)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", default="../corpus", help="Path to the corpus directory")
    parser.add_argument("--max-order", type=int, default=4, help="Highest n-gram order to count")
    parser.add_argument("--output-dir", default="data", help="Directory to write ngram_counts.json")
    args = parser.parse_args()

    path = analyze(args.corpus, args.max_order, args.output_dir)
    print(f"Wrote n-gram counts to {path}")
