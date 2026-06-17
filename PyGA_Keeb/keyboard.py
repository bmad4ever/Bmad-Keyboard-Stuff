"""Keyboard geometry and finger-mapping primitives.

Ports the static definitions from ``R LEGS/R/fitness/QueriesAndDefinitions.R``
into Python. The keyboard is modelled as a 3-row x 10-column grid (30 key
positions, 0-indexed here vs. the 1-indexed R original) holding the 26
letters plus the four punctuation characters required by claude.md
(``.``, ``,``, ``'``, ``;``), matching the 30-slot layout used by R LEGS.

Finger values: 1=left_pinky, 2=left_ring, 3=left_middle, 4=left_index,
5=right_index, 6=right_middle, 7=right_ring, 8=right_pinky (mirrors the
``9 - finger`` mapping used in the R source).
"""
from __future__ import annotations

from typing import Tuple

N_ROWS = 3
N_COLS = 10
N_KEYS = N_ROWS * N_COLS

# Character set: 26 lowercase letters + punctuation specified in claude.md.
# R LEGS used "-" as its 30th character; we use "'" per the project plan.
PUNCTUATION = (".", ",", "'", ";")
CHARACTERS: Tuple[str, ...] = tuple("abcdefghijklmnopqrstuvwxyz") + PUNCTUATION
assert len(CHARACTERS) == N_KEYS

FINGER_LEFT_PINKY = 1
FINGER_LEFT_RING = 2
FINGER_LEFT_MIDDLE = 3
FINGER_LEFT_INDEX = 4
FINGER_RIGHT_INDEX = 5
FINGER_RIGHT_MIDDLE = 6
FINGER_RIGHT_RING = 7
FINGER_RIGHT_PINKY = 8

# Ported verbatim from R LEGS/data/finger_map.txt (row-major, 1-indexed fingers).
FINGER_MAP: Tuple[int, ...] = (
    2, 2, 3, 4, 4, 5, 5, 6, 7, 7,
    1, 2, 3, 4, 4, 5, 5, 6, 7, 8,
    1, 2, 3, 4, 4, 5, 5, 6, 7, 8,
)
assert len(FINGER_MAP) == N_KEYS


def key_row(pos: int) -> int:
    """Row index (0-based) of a key position (0-based)."""
    return pos // N_COLS


def key_col(pos: int) -> int:
    """Column index (0-based) of a key position (0-based)."""
    return pos % N_COLS


def finger_of(pos: int) -> int:
    return FINGER_MAP[pos]


def ignore_hand(finger: int) -> int:
    """Collapse a hand-specific finger value to a hand-agnostic one (1..4)."""
    return 9 - finger if finger > 4 else finger


def is_left_hand(pos: int) -> bool:
    return key_col(pos) < 5


def are_same_hand(pos1: int, pos2: int) -> bool:
    return is_left_hand(pos1) == is_left_hand(pos2)


def is_same_key(pos1: int, pos2: int) -> bool:
    return pos1 == pos2


def is_same_finger(pos1: int, pos2: int) -> bool:
    return finger_of(pos1) == finger_of(pos2)


def is_home_row(pos: int) -> bool:
    return key_row(pos) == 1


def is_pinky(pos: int) -> bool:
    return finger_of(pos) in (FINGER_LEFT_PINKY, FINGER_RIGHT_PINKY)


def is_ring(pos: int) -> bool:
    return finger_of(pos) in (FINGER_LEFT_RING, FINGER_RIGHT_RING)


def is_middle(pos: int) -> bool:
    return finger_of(pos) in (FINGER_LEFT_MIDDLE, FINGER_RIGHT_MIDDLE)


def is_index(pos: int) -> bool:
    return finger_of(pos) in (FINGER_LEFT_INDEX, FINGER_RIGHT_INDEX)


def row_difference(pos1: int, pos2: int) -> int:
    """Row1 - Row2; negative means key2 is below key1."""
    return key_row(pos1) - key_row(pos2)


def abs_col_difference(pos1: int, pos2: int) -> int:
    return abs(key_col(pos1) - key_col(pos2))


def col_difference_same_hand(pos1: int, pos2: int, is_left: bool) -> int:
    """Signed column difference; negative = inward roll, positive = outward roll.

    Caller must ensure both keys are on the same hand (``is_left``).
    """
    if is_left:
        return key_col(pos1) - key_col(pos2)
    return key_col(pos2) - key_col(pos1)


def keys_dist_manhattan(pos1: int, pos2: int) -> int:
    return abs_col_difference(pos1, pos2) + abs(row_difference(pos1, pos2))


def keys_dist_euclidean(pos1: int, pos2: int) -> float:
    d_col = abs_col_difference(pos1, pos2)
    d_row = abs(row_difference(pos1, pos2))
    return (d_col ** 2 + d_row ** 2) ** 0.5


def fingers_used(positions, fingers_to_check) -> bool:
    """True if every finger in ``fingers_to_check`` appears among ``positions``."""
    used = {finger_of(p) for p in positions}
    return all(f in used for f in fingers_to_check)
