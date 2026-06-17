"""Fitness function for keyboard layouts.

A layout is represented as a tuple of 30 characters, ``layout[pos]`` being
the character assigned to key position ``pos`` (see keyboard.py for the
position numbering). Fitness is a single scalar where *lower is better*
(total typing effort), combining:

* Unigram cost: per-key reach effort (ported from R LEGS'
  ``data/singles_weight.txt``), weighted by how often each character is
  typed.
* Bigram cost: transition effort between consecutive characters
  (``costs.bigram_cost``).
* Higher-order costs (3..max_order): *marginal* sequential motion
  penalties (``costs.trigram_cost`` / ``fourgram_cost`` / ``fivegram_cost``)
  -- each one only charges effort that a shorter, overlapping n-gram could
  not already see (see costs.py's module docstring) -- restricted to the
  top-N most frequent n-grams of that order when ``top_n`` filtering is
  configured (see config.yaml / claude.md 4.2).

Each order's raw cost is normalized to [0, 1] by dividing by
``total_chars * max_cost_for_order``, where ``total_chars`` is the corpus's
total character count (the unigram total) -- the *same* denominator for
every order -- so every order's normalized component means the same
physical thing: "expected cost per character typed, attributable to this
order, as a fraction of worst-case." This is only meaningful because the
cost functions in costs.py were specifically redesigned to be
non-overlapping (no order re-penalizes a fact a shorter n-gram already
charged for); an earlier revision's higher-order functions did
double-count facts visible at a lower order, which is why a per-order
weight used to be *required* just to keep them from dominating.

An optional per-order ``weights`` multiplier (default 1.0, i.e. a no-op)
is still available on top of these normalized components -- not to
compensate for double-counting anymore, but as a convenience: it lets you
scale one order's overall influence up or down for experimentation without
having to re-derive every constant inside that order's cost function.
Because the components are already non-overlapping and comparably scaled,
there's no structural constraint on what these weights should be; treat
them as a tuning knob, not a correctness requirement.

Earlier draft used each order's own (possibly top-N-truncated) n-gram
occurrence count as the denominator instead. That produces a per-occurrence
*average* within that order's own sample, not a per-character contribution
-- two orders end up on different, incomparable scales (an order with a
handful of very costly n-grams scores identically to one with many
moderately-costly n-grams averaging to the same per-occurrence value, even
though their actual contribution to total typing effort differs by orders
of magnitude). Combining incomparable per-order averages with weights does
not reliably approximate total effort, which was the original flaw being
fixed in R LEGS' V1 fitness function -- so using the same flawed
normalization approach here would silently reintroduce it.
"""
from __future__ import annotations

from typing import Callable, Dict, List, Sequence, Tuple

from constraints import Constraint, total_penalty
from costs import COST_FUNCTIONS, MAX_COST_PER_ORDER, get_cost_functions
from keyboard import CHARACTERS, N_KEYS

Layout = Tuple[str, ...]

# Per-key reach effort, ported from R LEGS/data/singles_weight.txt
# (row-major, 3x10 grid; lower = easier to reach).
POSITION_EFFORT: Tuple[float, ...] = (
    8, 5, 2, 2, 5, 5, 2, 2, 5, 8,
    4, 2, 1, 1, 3, 3, 1, 1, 2, 4,
    7, 4, 3, 2, 4, 4, 2, 3, 4, 7,
)
assert len(POSITION_EFFORT) == N_KEYS
MAX_POSITION_EFFORT = max(POSITION_EFFORT)


def char_to_pos(layout: Layout) -> Dict[str, int]:
    return {ch: pos for pos, ch in enumerate(layout)}


def random_layout(rng) -> Layout:
    chars = list(CHARACTERS)
    rng.shuffle(chars)
    return tuple(chars)


def _filtered_ngrams(counts_for_order: Dict[str, int], n: int | None) -> Dict[str, int]:
    if n is None or len(counts_for_order) <= n:
        return counts_for_order
    return dict(sorted(counts_for_order.items(), key=lambda kv: -kv[1])[:n])


def prefilter_ngram_data(
    ngram_data: Dict[str, Dict[str, int]], top_n: Dict[int, int | None] | None = None
) -> Dict[str, Dict[str, int]]:
    """Apply top-N filtering once, up front.

    ``ngram_data`` and ``top_n`` don't change across a GA run (only the
    candidate layout does), so re-sorting a full per-order dict (up to tens
    of thousands of entries for a large corpus) inside every single
    ``compute_fitness`` call -- once per individual, per generation -- is
    pure waste: the same top-N result gets recomputed unchanged on every
    call. Call this once before a hot loop and reuse its result; passing
    the same ``top_n`` into ``compute_fitness`` afterwards remains correct
    (and cheap) since ``_filtered_ngrams`` is a no-op once a dict is
    already at or under size ``n``.
    """
    top_n = top_n or {}
    filtered: Dict[str, Dict[str, int]] = {}
    for key, counts in ngram_data.items():
        if key == "1":
            filtered[key] = counts
            continue
        filtered[key] = _filtered_ngrams(counts, top_n.get(int(key)))
    return filtered


def unigram_component(layout: Layout, unigram_counts: Dict[str, int]) -> float:
    positions = char_to_pos(layout)
    total_count = sum(unigram_counts.values())
    if total_count == 0:
        return 0.0
    raw = sum(count * POSITION_EFFORT[positions[ch]] for ch, count in unigram_counts.items() if ch in positions)
    return raw / (total_count * MAX_POSITION_EFFORT)


def ngram_component(
    layout: Layout,
    order: int,
    ngram_counts: Dict[str, int],
    top_n: int | None,
    total_chars: int,
    cost_functions: Dict[int, Callable] | None = None,
) -> float:
    """Normalized cost contribution of n-grams of ``order``.

    ``total_chars`` (the corpus's total character count, i.e. the unigram
    total) is used as the denominator for *every* order, not that order's
    own occurrence count. This is required for cross-order comparability:
    each order's score must mean "expected cost per character typed,
    attributable to this order, as a fraction of worst-case" -- the same
    physical quantity for every order -- otherwise weighting rare-but-costly
    n-grams the same as frequent-but-costly ones (because each was averaged
    over its own sample) silently breaks the relationship between the
    weights and actual total typing effort. That mismatch is exactly the
    flaw that made the original R LEGS V1 fitness function unreliable.

    Top-N filtering (a performance optimization, see config.yaml) means
    ``raw`` only sums the most frequent n-grams of this order; the omitted
    long tail is undercounted as zero. This is a deliberate, documented
    approximation (the omitted mass is small for a large enough top_n), not
    a normalization error -- unlike the per-order-total bug this replaces.
    """
    positions = char_to_pos(layout)
    cost_fn = (cost_functions or COST_FUNCTIONS)[order]
    filtered = _filtered_ngrams(ngram_counts, top_n)
    if total_chars == 0:
        return 0.0
    raw = 0.0
    for ngram, count in filtered.items():
        try:
            pos_seq = tuple(positions[ch] for ch in ngram)
        except KeyError:
            continue
        raw += count * cost_fn(*pos_seq)
    return raw / (total_chars * MAX_COST_PER_ORDER[order])


def compute_fitness(
    layout: Layout,
    ngram_data: Dict[str, Dict[str, int]],
    weights: Dict[int, float] | None = None,
    top_n: Dict[int, int | None] | None = None,
    constraints: List[Constraint] | None = None,
    allow_swipe_motions: bool = True,
) -> float:
    """Total normalized typing effort for ``layout`` (lower is better).

    Every order present in ``ngram_data`` with a registered cost function
    contributes its normalized component, multiplied by ``weights.get(order,
    1.0)``. The default of 1.0 for any order not listed in ``weights`` means
    omitting ``weights`` entirely reproduces the unweighted sum. Unlike the
    old per-order weight (removed, then reinstated here), this one is a pure
    tuning knob: it is *not* compensating for any double-counting between
    orders (costs.py's higher-order functions only charge marginal effort,
    see its module docstring), so there is no structural requirement on
    these values -- they just let you scale one order's influence up or down
    without having to re-derive every constant inside that order's cost
    function.

    ``allow_swipe_motions`` (default True, matching the original R LEGS
    model): whether the bigram cost treats certain same-finger transitions
    as a cheap "swipe" (sliding a finger across the keycap to an adjacent
    key instead of lifting and re-pressing). Most physical keyboards don't
    actually support this, so set it to False to charge those transitions
    at the same "lift and re-press" rate as any other same-finger pair.
    See ``costs.bigram_cost``'s docstring for exactly which transitions
    this affects.

    ``constraints`` are optional soft penalties (claude.md 4.4, ported from
    R LEGS' ``scorePenalty``): each violated constraint adds its configured
    weight on top of the effort total, so the GA is pushed away from
    layouts that violate them without making them strictly infeasible.
    """
    weights = weights or {}
    top_n = top_n or {}
    cost_functions = get_cost_functions(allow_swipe_motions)
    total_chars = sum(ngram_data.get("1", {}).values())
    total = weights.get(1, 1.0) * unigram_component(layout, ngram_data.get("1", {}))

    for order in sorted(int(k) for k in ngram_data if k != "1"):
        if order not in cost_functions:
            continue
        counts_for_order = ngram_data[str(order)]
        if not counts_for_order:
            continue
        total += weights.get(order, 1.0) * ngram_component(
            layout, order, counts_for_order, top_n.get(order), total_chars, cost_functions
        )

    if constraints:
        total += total_penalty(layout, constraints)

    return total


def fitness_components(
    layout: Layout,
    ngram_data: Dict[str, Dict[str, int]],
    weights: Dict[int, float] | None = None,
    top_n: Dict[int, int | None] | None = None,
    allow_swipe_motions: bool = True,
) -> Dict[int, float]:
    """Per-order (weighted, normalized) contributions -- useful for debugging/validation.

    See ``compute_fitness`` for what ``allow_swipe_motions`` does.
    """
    weights = weights or {}
    top_n = top_n or {}
    cost_functions = get_cost_functions(allow_swipe_motions)
    total_chars = sum(ngram_data.get("1", {}).values())
    components: Dict[int, float] = {1: weights.get(1, 1.0) * unigram_component(layout, ngram_data.get("1", {}))}
    for order in sorted(int(k) for k in ngram_data if k != "1"):
        if order not in cost_functions:
            continue
        counts_for_order = ngram_data[str(order)]
        components[order] = (
            weights.get(order, 1.0)
            * ngram_component(layout, order, counts_for_order, top_n.get(order), total_chars, cost_functions)
            if counts_for_order
            else 0.0
        )
    return components


def validate_weights(weights: Dict[int, float]) -> List[str]:
    """Advisory sanity-check for configured weights; returns warning strings (empty = OK).

    These are no longer enforcing a structural requirement (there is no
    double-counting left to compensate for), just flagging likely typos:
    a negative weight, or a higher-order weight far exceeding a lower
    order's -- which is allowed, but unusual enough to be worth a second
    look before a long GA run.
    """
    warnings: List[str] = []
    for order, weight in weights.items():
        if weight < 0:
            warnings.append(f"order {order} has a negative weight ({weight})")

    orders = sorted(weights)
    for i in range(1, len(orders)):
        lower_order, higher_order = orders[i - 1], orders[i]
        if weights[higher_order] > weights[lower_order]:
            warnings.append(
                f"order {higher_order} weight ({weights[higher_order]}) exceeds "
                f"order {lower_order} weight ({weights[lower_order]}); double-check this is intentional"
            )
    return warnings
