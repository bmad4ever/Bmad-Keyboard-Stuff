"""Motion-cost (effort) functions for n-grams typed on the 30-key layout.

These are adapted from the R LEGS reference implementation in
``R LEGS/R/fitness/efforts/`` (NOT the deprecated V1 versions). The R files
are left untouched; this module re-implements the same heuristics in Python
and documents every deviation.

Revisions made relative to the R source (see claude.md Section 3.2):

* The R code pre-computed full dense cost matrices/hashmaps for every
  possible n-gram of every order (e.g. looping ``i1..i5`` over 30 positions,
  30**5 ~= 24M evaluations for 5-grams). Since `fitness.py` only ever needs
  the cost of n-grams that actually occur in the corpus (and only the
  top-N most frequent ones for order > 2, per the project plan's
  performance mitigation), costs are computed on demand instead of
  pre-computed for every permutation. The formulas themselves are
  unchanged, just evaluated lazily.
* Each order's cost function is allowed to re-evaluate a fact that a
  shorter, overlapping sub-sequence could also see (e.g. "this whole
  trigram relies only on the pinky and ring fingers" is partly visible at
  the bigram level too). This is intentional, not an oversight: the corpus
  is scanned independently at every order (every bigram, trigram, 4-gram,
  5-gram occurring in the text is counted and costed separately), and a
  sustained run on weak fingers, or a sequence that keeps swapping hands,
  represents *cumulative*/repetitive-motion and higher-order hand-motion
  effort that compounds beyond any single pairwise transition -- a 3-key
  pinky/ring run is plausibly more fatiguing than the sum of its two
  bigram transitions taken in isolation. The hand-alternation penalties
  specifically also stand in for something no per-keystroke effort tally
  can otherwise represent: heavy, constant alternation (switching hands
  on every keystroke for several keys running) removes any rolling rhythm
  and forces tight inter-hand timing, which is the kind of coordination
  overhead that produces typing errors at speed -- a cost this model has
  no other way to charge for. That's a deliberate choice to fill a real
  gap rather than a double-count of motion effort already charged at the
  bigram level (the flat different-hand bigram cost doesn't distinguish
  an easy cross-hand pairing from an awkward one, so nothing here repeats
  that). Because this means the same underlying motion can be charged at
  more than one order, the per-order `weights` in `fitness.py`/
  `config.yaml` (default 1.0 each) are the intended way to rebalance how
  much influence each order has on the total, rather than editing the
  constants inside these cost functions directly.
"""
from __future__ import annotations

from typing import Sequence

from keyboard import (
    abs_col_difference,
    are_same_hand,
    col_difference_same_hand,
    finger_of,
    is_home_row,
    is_index,
    is_left_hand,
    is_middle,
    is_pinky,
    is_ring,
    is_same_finger,
    is_same_key,
    key_col,
    key_row,
    keys_dist_euclidean,
    row_difference,
    FINGER_LEFT_INDEX,
    FINGER_LEFT_MIDDLE,
    FINGER_LEFT_PINKY,
    FINGER_LEFT_RING,
    FINGER_RIGHT_INDEX,
    FINGER_RIGHT_MIDDLE,
    FINGER_RIGHT_PINKY,
    FINGER_RIGHT_RING,
    ignore_hand,
)

# ---------------------------------------------------------------------------
# Bigram motion costs (ported from 2GramEffortMatrix.R)
# ---------------------------------------------------------------------------

BIGRAM_DIFFERENT_HAND = 2.0
BIGRAM_INNER_ROLL = 1.0
BIGRAM_OUTER_ROLL = 3.0
BIGRAM_PER_ROW_DIFF_DIFFERENT_FINGERS = 1.0
# indexed by hand-agnostic finger - 1 (pinky, ring, middle, index)
BIGRAM_SAME_FINGER_SAME_KEY = (4.0, 3.0, 2.5, 2.5)
BIGRAM_SAME_FINGER_NO_SWIPE = (5.0, 4.0, 3.5, 3.5)
BIGRAM_SIDE_SWIPE = 2.0
BIGRAM_DOWN_SWIPE = 2.0
# indexed by abs row difference (0, 1, 2)
BIGRAM_PINKY_RING_PENALTY = (1.0, 1.0, 3.0)
BIGRAM_MIDDLE_INDEX_STRETCH_PENALTY = (2.0, 2.0, 3.0)

# Per-instance maximum possible bigram cost, used to normalize this order's
# total contribution in fitness.py (worst case: outer roll + both penalties
# at the largest row difference).
BIGRAM_MAX_COST = max(BIGRAM_SAME_FINGER_NO_SWIPE) * (2 ** 0.5) + 0  # fallback
BIGRAM_MAX_COST = max(
    BIGRAM_MAX_COST,
    2 * BIGRAM_PER_ROW_DIFF_DIFFERENT_FINGERS
    + BIGRAM_OUTER_ROLL
    + BIGRAM_PINKY_RING_PENALTY[-1]
    + BIGRAM_MIDDLE_INDEX_STRETCH_PENALTY[-1],
)


def _is_downward(row_diff: int) -> bool:
    return row_diff < 0


def _is_possible_index_side_swipe(pos1: int, pos2: int, left_hand: bool, row_diff: int) -> bool:
    return (
        is_index(pos1)
        and is_home_row(pos2)
        and not (row_diff > 0)
        and col_difference_same_hand(pos1, pos2, left_hand) == 1
    )


def _is_possible_vertical_swipe(pos1: int, pos2: int, row_diff: int) -> bool:
    return row_diff == -1 and not is_pinky(pos1) and abs_col_difference(pos1, pos2) == 0


def _uses_pinky_and_ring(pos1: int, pos2: int) -> bool:
    fingers = {finger_of(pos1), finger_of(pos2)}
    return fingers == {FINGER_LEFT_PINKY, FINGER_LEFT_RING} or fingers == {
        FINGER_RIGHT_PINKY,
        FINGER_RIGHT_RING,
    }


def _uses_index_middle_stretch(pos1: int, pos2: int) -> bool:
    fingers = {finger_of(pos1), finger_of(pos2)}
    same_hand_pair = fingers == {FINGER_LEFT_MIDDLE, FINGER_LEFT_INDEX} or fingers == {
        FINGER_RIGHT_MIDDLE,
        FINGER_RIGHT_INDEX,
    }
    return same_hand_pair and abs_col_difference(pos1, pos2) > 1


def bigram_cost(pos1: int, pos2: int, allow_swipes: bool = True) -> float:
    """Cost of transitioning from key ``pos1`` to key ``pos2``.

    ``allow_swipes`` controls the two same-finger "swipe" shortcuts (rules
    #2/#3 in COST_RULES.md): keeping a finger pressed against the keycap
    while sliding it onto an adjacent key, rather than lifting and
    re-pressing. Most physical keyboards (mechanical, membrane, scissor-
    switch -- anything with per-key actuation) don't actually support this;
    it's a niche assumption baked into the original R LEGS model, not a
    universal one. With ``allow_swipes=False``, those same-finger pairs
    fall through to the general "lift and re-press" cost
    (``BIGRAM_SAME_FINGER_NO_SWIPE`` scaled by distance) like any other
    same-finger transition. See ``fitness.compute_fitness``'s
    ``allow_swipe_motions`` parameter / ``config.yaml`` to set this
    project-wide instead of passing it through manually.
    """
    left_hand = is_left_hand(pos1)
    row_diff = row_difference(pos1, pos2)

    if is_same_finger(pos1, pos2):
        if is_same_key(pos1, pos2):
            return BIGRAM_SAME_FINGER_SAME_KEY[ignore_hand(finger_of(pos1)) - 1]
        if allow_swipes and _is_possible_index_side_swipe(pos1, pos2, left_hand, row_diff):
            return BIGRAM_SIDE_SWIPE
        if allow_swipes and _is_possible_vertical_swipe(pos1, pos2, row_diff):
            return BIGRAM_DOWN_SWIPE
        finger = ignore_hand(finger_of(pos1))
        return BIGRAM_SAME_FINGER_NO_SWIPE[finger - 1] * keys_dist_euclidean(pos1, pos2)

    if left_hand != is_left_hand(pos2):
        return BIGRAM_DIFFERENT_HAND

    abs_row_diff = abs(row_diff)
    cost = abs_row_diff * BIGRAM_PER_ROW_DIFF_DIFFERENT_FINGERS
    if col_difference_same_hand(pos1, pos2, left_hand) < 0:
        cost += BIGRAM_INNER_ROLL
    else:
        cost += BIGRAM_OUTER_ROLL

    if _uses_pinky_and_ring(pos1, pos2):
        cost += BIGRAM_PINKY_RING_PENALTY[abs_row_diff]
    if _uses_index_middle_stretch(pos1, pos2):
        cost += BIGRAM_MIDDLE_INDEX_STRETCH_PENALTY[abs_row_diff]

    return cost


def bigram_cost_no_swipe(pos1: int, pos2: int) -> float:
    """``bigram_cost`` with ``allow_swipes=False`` -- see that function's
    docstring. A plain ``(pos1, pos2) -> float`` callable so it can be
    used as a drop-in entry in a ``COST_FUNCTIONS``-shaped dict (see
    ``get_cost_functions``)."""
    return bigram_cost(pos1, pos2, allow_swipes=False)


def get_cost_functions(allow_swipe_motions: bool = True) -> dict:
    """Return a ``COST_FUNCTIONS``-shaped dict (order -> cost function),
    using the swipe-disabled bigram cost when ``allow_swipe_motions`` is
    False. The true worst-case bigram cost is unaffected either way (8.94,
    below ``BIGRAM_MAX_COST``'s 11.0 upper bound -- verified by brute force
    over all 30x30 key pairs), so ``MAX_COST_PER_ORDER`` does not need a
    swipe-disabled variant."""
    return {
        2: bigram_cost if allow_swipe_motions else bigram_cost_no_swipe,
        3: trigram_cost,
        4: fourgram_cost,
        5: fivegram_cost,
    }


# ---------------------------------------------------------------------------
# Trigram motion costs (ported from 3GramsEffortMatrix.R)
# ---------------------------------------------------------------------------

TRIGRAM_PINKY_RING_MIDDLE_DOWNWARD_PENALTY = 2.0
TRIGRAM_RING_MIDDLE_INDEX_UPWARD_PENALTY = 2.0
TRIGRAM_ONLY_PINKY_AND_RING_PENALTY = 3.0
TRIGRAM_NO_ROLL_PENALTY = 1.0
# indexed by (sum of consecutive abs row diffs - 1), valid sums are 2, 3, 4
TRIGRAM_NON_MONOTONIC_ROWS_PENALTY = (1.0, 2.0, 5.0)
TRIGRAM_HAND_SWAP_2X = TRIGRAM_NO_ROLL_PENALTY

TRIGRAM_MAX_COST = (
    TRIGRAM_ONLY_PINKY_AND_RING_PENALTY
    + TRIGRAM_NON_MONOTONIC_ROWS_PENALTY[-1]
    + max(TRIGRAM_PINKY_RING_MIDDLE_DOWNWARD_PENALTY, TRIGRAM_RING_MIDDLE_INDEX_UPWARD_PENALTY)
)


def _is_unsorted(values: Sequence[int]) -> bool:
    return any(values[i] > values[i + 1] for i in range(len(values) - 1))


def trigram_cost(pos1: int, pos2: int, pos3: int) -> float:
    cost = 0.0

    if are_same_hand(pos1, pos2) and are_same_hand(pos2, pos3):
        fingers = [finger_of(pos1), finger_of(pos2), finger_of(pos3)]
        rows = [key_row(pos1), key_row(pos2), key_row(pos3)]
        cols = [key_col(pos1), key_col(pos2), key_col(pos3)]

        unique_fingers = set(fingers)
        if len(unique_fingers) == 1:
            pass  # single-finger sequences are covered by bigram swipe costs
        elif unique_fingers <= {FINGER_LEFT_PINKY, FINGER_LEFT_RING} or unique_fingers <= {
            FINGER_RIGHT_PINKY,
            FINGER_RIGHT_RING,
        }:
            cost += TRIGRAM_ONLY_PINKY_AND_RING_PENALTY
        elif _is_unsorted(cols) and _is_unsorted(list(reversed(cols))):
            cost += TRIGRAM_NO_ROLL_PENALTY

        if len(unique_fingers) == 3 and _is_unsorted(rows) and _is_unsorted(list(reversed(rows))):
            # row_span in {2, 3, 4} (rows are non-monotonic with 3 distinct
            # fingers, so each step is non-zero) -> index 0, 1, 2
            row_span = abs(rows[0] - rows[1]) + abs(rows[1] - rows[2])
            cost += TRIGRAM_NON_MONOTONIC_ROWS_PENALTY[row_span - 2]

        if (
            fingers[0] in (FINGER_LEFT_PINKY, FINGER_RIGHT_PINKY)
            and fingers[1] in (FINGER_LEFT_RING, FINGER_RIGHT_RING)
            and fingers[2] in (FINGER_LEFT_MIDDLE, FINGER_RIGHT_MIDDLE)
            and rows[0] + 1 < rows[2]
        ):
            cost += TRIGRAM_PINKY_RING_MIDDLE_DOWNWARD_PENALTY

        if (
            fingers[0] in (FINGER_LEFT_RING, FINGER_RIGHT_RING)
            and fingers[1] in (FINGER_LEFT_MIDDLE, FINGER_RIGHT_MIDDLE)
            and fingers[2] in (FINGER_LEFT_INDEX, FINGER_RIGHT_INDEX)
            and rows[0] > 1 + rows[2]
        ):
            cost += TRIGRAM_RING_MIDDLE_INDEX_UPWARD_PENALTY

    elif not are_same_hand(pos1, pos2) and not are_same_hand(pos2, pos3):
        cost += TRIGRAM_HAND_SWAP_2X

    return cost


# ---------------------------------------------------------------------------
# 4-gram motion costs (ported from 4GramEffortFunction.R)
# ---------------------------------------------------------------------------

FOURGRAM_DOUBLE_VERTICAL_DIRECTION_CHANGE = (1.0, 2.0)  # indexed by min |row diff| - 1
FOURGRAM_ONLY_PINKY_AND_RING_PENALTY = 1.0
FOURGRAM_HAND_SWAP_3X = 1.0

FOURGRAM_MAX_COST = (
    FOURGRAM_ONLY_PINKY_AND_RING_PENALTY + FOURGRAM_DOUBLE_VERTICAL_DIRECTION_CHANGE[-1]
)


def fourgram_cost(pos1: int, pos2: int, pos3: int, pos4: int) -> float:
    cost = 0.0

    if are_same_hand(pos1, pos2) and are_same_hand(pos2, pos3) and are_same_hand(pos3, pos4):
        fingers = [finger_of(pos1), finger_of(pos2), finger_of(pos3), finger_of(pos4)]
        rows = [key_row(pos1), key_row(pos2), key_row(pos3), key_row(pos4)]

        unique_fingers = set(fingers)
        if unique_fingers <= {FINGER_LEFT_PINKY, FINGER_LEFT_RING} or unique_fingers <= {
            FINGER_RIGHT_PINKY,
            FINGER_RIGHT_RING,
        }:
            cost += FOURGRAM_ONLY_PINKY_AND_RING_PENALTY

        row_diffs = [rows[i + 1] - rows[i] for i in range(3)]
        if (row_diffs[0] > 0 and row_diffs[1] < 0 and row_diffs[2] > 0) or (
            row_diffs[0] < 0 and row_diffs[1] > 0 and row_diffs[2] < 0
        ):
            nonzero = [abs(d) for d in row_diffs if d != 0]
            idx = min(nonzero) - 1 if nonzero else 0
            idx = min(idx, len(FOURGRAM_DOUBLE_VERTICAL_DIRECTION_CHANGE) - 1)
            cost += FOURGRAM_DOUBLE_VERTICAL_DIRECTION_CHANGE[idx]

    elif (
        not are_same_hand(pos1, pos2)
        and not are_same_hand(pos2, pos3)
        and not are_same_hand(pos3, pos4)
    ):
        cost += FOURGRAM_HAND_SWAP_3X

    return cost


# ---------------------------------------------------------------------------
# 5-gram motion costs (ported from 5GramEffortFunction.R)
# ---------------------------------------------------------------------------

FIVEGRAM_NO_HAND_ALTERNATION_PENALTY = 3.0
FIVEGRAM_MAX_COST = FIVEGRAM_NO_HAND_ALTERNATION_PENALTY


def fivegram_cost(pos1: int, pos2: int, pos3: int, pos4: int, pos5: int) -> float:
    fingers = [finger_of(p) for p in (pos1, pos2, pos3, pos4, pos5)]
    if all(f <= 4 for f in fingers) or all(f >= 5 for f in fingers):
        return FIVEGRAM_NO_HAND_ALTERNATION_PENALTY
    return 0.0


COST_FUNCTIONS = {
    2: bigram_cost,
    3: trigram_cost,
    4: fourgram_cost,
    5: fivegram_cost,
}

MAX_COST_PER_ORDER = {
    2: BIGRAM_MAX_COST,
    3: TRIGRAM_MAX_COST,
    4: FOURGRAM_MAX_COST,
    5: FIVEGRAM_MAX_COST,
}
