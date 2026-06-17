"""Optional layout constraints (claude.md 4.4 / R LEGS ``R/fitness/constraints/``).

R LEGS supports a handful of *optional* constraints on top of the core
effort fitness: forcing specific characters onto specific key positions
(``SymbolConstraintF.R``), and forcing all vowels onto one hand
(``VowelConstraintF.R``). Both are implemented there as soft fitness
penalties rather than hard repairs: a boolean predicate over the full
layout, paired with a penalty weight subtracted from fitness when the
predicate is false (see ``R/V1/Fitness.R`` ``scorePenalty`` /
``AuxFunctions.R`` ``penalty.compute``).

This module ports that same soft-constraint design (predicate + weight,
summed into the fitness total) and adds one more constraint claude.md asks
for that R LEGS does not have: forcing non-letter characters into the four
outer-corner key positions of the 3x10 grid.

Each constraint here is a ``Constraint`` with a ``check(layout) -> bool``
predicate and a ``weight``; an individual that violates the constraint is
penalized by exactly ``weight`` (added to the normalized fitness total,
which is minimized), mirroring R LEGS' ``(1 - bool(constraint)) * weight``.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Tuple

from keyboard import N_KEYS, is_left_hand

Layout = Tuple[str, ...]

VOWELS = ("a", "e", "i", "o", "u")  # matches R LEGS VowelConstraintF.R (y excluded)
OUTER_CORNERS = (0, 9, 20, 29)  # flattened 3x10 grid: top-left, top-right, bottom-left, bottom-right
# This models a split keyboard: columns 0-4 are the left half, columns 5-9
# the right half, each with its own 4 corners. OUTER_CORNERS (above) are the
# 4 corners facing *away* from the split (the device's outer edges).
# INNER_CORNERS are the 4 corners facing the split gap -- column 4 (left
# half's inner edge) and column 5 (right half's inner edge), top and bottom.
INNER_CORNERS = (4, 5, 24, 25)
BOTTOM_OUTER_CORNERS = (20, 29)
# All inner + outer corners except the two bottom outer corners: top-left and
# top-right outer corners, all four inner corners, but not bottom-left/right outer.
EXTENDED_CORNERS = tuple(sorted((set(OUTER_CORNERS) | set(INNER_CORNERS)) - set(BOTTOM_OUTER_CORNERS)))


@dataclass
class Constraint:
    name: str
    check: Callable[[Layout], bool]
    weight: float

    def penalty(self, layout: Layout) -> float:
        return 0.0 if self.check(layout) else self.weight


def fixed_positions_constraint(fixed: Dict[str, int], weight: float) -> Constraint:
    """All characters in ``fixed`` (char -> 0-indexed key position) must be at that position."""

    def check(layout: Layout) -> bool:
        return all(layout[pos] == ch for ch, pos in fixed.items())

    names = ", ".join(f"{ch}@{pos}" for ch, pos in fixed.items())
    return Constraint(name=f"fixed_positions[{names}]", check=check, weight=weight)


def vowels_side_constraint(side: str, weight: float) -> Constraint:
    """All vowels (a, e, i, o, u) must be on the same hand ('left' or 'right')."""
    if side not in ("left", "right"):
        raise ValueError("side must be 'left' or 'right'")
    want_left = side == "left"

    def check(layout: Layout) -> bool:
        positions = {ch: pos for pos, ch in enumerate(layout)}
        return all(is_left_hand(positions[v]) == want_left for v in VOWELS if v in positions)

    return Constraint(name=f"vowels_on_{side}", check=check, weight=weight)


def non_letters_outer_corners_constraint(weight: float) -> Constraint:
    """Every non-letter character (punctuation) must sit in one of the four outer-corner keys."""

    def check(layout: Layout) -> bool:
        non_letters = [ch for ch in layout if not ch.isalpha()]
        corner_chars = {layout[pos] for pos in OUTER_CORNERS}
        return all(ch in corner_chars for ch in non_letters)

    return Constraint(name="non_letters_in_outer_corners", check=check, weight=weight)


def non_letters_extended_corners_constraint(weight: float) -> Constraint:
    """Every non-letter character must sit in an inner or outer corner key,
    excluding the two bottom outer corners (positions 20 and 29).

    Models a split keyboard: outer corners (0, 9, 20, 29) face the device's
    outer edges, inner corners (4, 5, 24, 25) face the split gap between
    the left half (columns 0-4) and right half (columns 5-9). Combined and
    minus the bottom outer corners, the allowed set is (0, 4, 5, 9, 24, 25).
    """

    def check(layout: Layout) -> bool:
        non_letters = [ch for ch in layout if not ch.isalpha()]
        corner_chars = {layout[pos] for pos in EXTENDED_CORNERS}
        return all(ch in corner_chars for ch in non_letters)

    return Constraint(name="non_letters_in_extended_corners", check=check, weight=weight)


def build_constraints(spec: Optional[dict]) -> List[Constraint]:
    """Build a list of Constraint objects from a config.yaml-style ``constraints`` section.

    Expected shape (all keys optional)::

        constraints:
          fixed_positions:
            weight: 0.1
            positions: {"e": 13}       # char -> 0-indexed key position
          vowels_side:
            weight: 0.1
            side: left                  # or "right"
          non_letters_outer_corners:
            weight: 0.1
          non_letters_extended_corners:
            weight: 0.1
    """
    if not spec:
        return []
    constraints: List[Constraint] = []

    fp = spec.get("fixed_positions")
    if fp:
        constraints.append(fixed_positions_constraint(fp["positions"], fp.get("weight", 0.1)))

    vs = spec.get("vowels_side")
    if vs:
        constraints.append(vowels_side_constraint(vs.get("side", "left"), vs.get("weight", 0.1)))

    oc = spec.get("non_letters_outer_corners")
    if oc:
        constraints.append(non_letters_outer_corners_constraint(oc.get("weight", 0.1)))

    ec = spec.get("non_letters_extended_corners")
    if ec:
        constraints.append(non_letters_extended_corners_constraint(ec.get("weight", 0.1)))

    return constraints


def total_penalty(layout: Layout, constraints: List[Constraint]) -> float:
    return sum(c.penalty(layout) for c in constraints)
