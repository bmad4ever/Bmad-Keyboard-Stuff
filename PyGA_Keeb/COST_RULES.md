# Cost Rules and Weights

This document lists, in plain English, every typing-effort rule encoded in
`fitness.py` (per-key reach effort) and `costs.py` (n-gram motion costs).

Each order's raw cost is normalized to `[0, 1]` by dividing by
`total_chars * max_cost_for_order` (`total_chars` is the corpus's total
character count — the same denominator for every order, see `fitness.py`),
and the normalized components are then summed, each multiplied by an
optional per-order `weights` entry from `config.yaml` (default 1.0, a
no-op if omitted).

That weight matters here in a way it wouldn't if the orders were strictly
non-overlapping: a higher-order cost function is deliberately allowed to
re-evaluate a fact a shorter, overlapping n-gram could also see (e.g. "this
whole trigram relies only on the pinky and ring fingers" overlaps with what
the bigram-level pinky/ring penalty already sees one pair at a time). This
is intentional — a sustained run on weak fingers, or a sequence that keeps
swapping hands, represents *cumulative*/repetitive-motion and higher-order
hand-motion effort that compounds beyond any single pairwise transition, so
it's modeled again at each order it's visible at, rather than only once at
the lowest order that can see it. Because the same underlying motion can
therefore be charged at more than one order, the per-order `weights` are
the intended way to rebalance how much influence each order has on the
total, without editing the constants inside any cost function directly.

## 1. Per-key reach effort (unigram, order 1)

**Rule:** every key position has a fixed "how hard is it to reach this key"
cost, independent of what came before or after it. Frequently-typed
characters are charged this cost every time they occur.

| Row | Pinky | Ring | Middle | Index | Index | Index | Index | Middle | Ring | Pinky |
|---|---|---|---|---|---|---|---|---|---|---|
| Top    | 8 | 5 | 2 | 2 | 5 | 5 | 2 | 2 | 5 | 8 |
| Home   | 4 | 2 | 1 | 1 | 3 | 3 | 1 | 1 | 2 | 4 |
| Bottom | 7 | 4 | 3 | 2 | 4 | 4 | 2 | 3 | 4 | 7 |

(Lower = easier. Home-row index "home" keys cost 1; the index finger's
reach to the adjacent home-row key costs 3. Top-row corners cost the
maximum, 8.)

## 2. Bigram motion costs (order 2)

Applied to every pair of consecutive characters.

| # | Rule (plain English) | Weight |
|---|---|---|
| 1 | Same finger presses the *same key* twice in a row. Penalty is higher for weaker fingers. | pinky 4.0, ring 3.0, middle 2.5, index 2.5 |
| 2 | Same finger, *different* key, but it's an index-finger "side swipe" onto an adjacent home-row key (no direction reversal) — treated as a cheap, natural motion *if your keyboard supports swiping* (see below). | 2.0 |
| 3 | Same finger, different key, but it's a non-pinky finger swiping straight down one row in the same column — also treated as cheap *if swiping is supported*. | 2.0 |
| 4 | Same finger, different key, no swipe pattern applies (the general/worst case): per-finger base cost, multiplied by the Euclidean distance between the two keys. | pinky 5.0, ring 4.0, middle 3.5, index 3.5 (×distance) |
| 5 | The two characters are on different hands. Flat cost, regardless of which keys or how far apart -- this deliberately does not model the cross-hand "shape" (which specific fingers pair up, mirroring the inner/outer roll distinction same-hand pairs get). See the analysis section below for why. | 2.0 |
| 6 | Same hand, different fingers: charge per row crossed... | 1.0 per row |
| 6a | ...plus a cost for the roll direction: rolling *inward* (toward the hand's center, e.g. pinky→index) is cheap... | 1.0 |
| 6b | ...while rolling *outward* (away from center, e.g. index→pinky) is expensive. | 3.0 |
| 6c | ...plus an extra penalty if the pair specifically uses the pinky+ring fingers together, scaling up at larger row distances. | 1.0 (rows 0–1), 3.0 (row 2) |
| 6d | ...plus an extra penalty if the pair specifically uses the middle+index fingers reaching more than one column apart (a stretch), scaling up at larger row distances. | 2.0 (rows 0–1), 3.0 (row 2) |

**Swipe motions (rules #2/#3) are optional.** Most physical keyboards
(mechanical, membrane, scissor-switch) don't support sliding a finger
across a keycap onto an adjacent key while keeping it pressed -- this was
the original R LEGS assumption, not a universal one. Set
`fitness.allow_swipe_motions: false` in your config (or pass
`allow_swipe_motions=False` to `fitness.compute_fitness`/
`fitness_components`) to charge those same-finger transitions at the
regular "lift and re-press" rate instead (`BIGRAM_SAME_FINGER_NO_SWIPE`
scaled by distance, same as rule #4). The worst-case bigram cost is
unaffected either way -- verified by brute force over all 30x30 key pairs,
the true maximum (8.94) sits below `BIGRAM_MAX_COST`'s normalization
ceiling (11.0) in both modes, so no separate normalization constant is
needed when swipes are disabled. See `costs.bigram_cost`'s docstring.

## 3. Trigram motion costs (order 3)

Applied to every 3 consecutive characters.

| # | Rule (plain English) | Weight |
|---|---|---|
| 1 | All three letters typed by the *same single finger*. No extra trigram penalty (already covered by the bigram same-finger costs). | 0.0 |
| 2 | All three letters stay on one hand and use *only* the pinky and ring fingers (no stronger finger involved). | 3.0 |
| 3 | All three letters stay on one hand, use more than just pinky/ring, but don't move smoothly in one direction across the columns (the motion zig-zags rather than rolling). | 1.0 |
| 4 | All three letters stay on one hand, use 3 distinct fingers, *and* the rows also zig-zag (up-then-down or down-then-up). Penalty grows with total row distance covered. | 1.0 (span 2), 2.0 (span 3), 5.0 (span 4) |
| 5 | The specific finger sequence pinky→ring→middle, moving down more than one row overall. | 2.0 |
| 6 | The specific finger sequence ring→middle→index, moving up more than one row overall. | 2.0 |
| 7 | The three letters fully alternate hands on every keystroke (left-right-left or right-left-right). | 1.0 |

## 4. 4-gram motion costs (order 4)

Applied to every 4 consecutive characters.

| # | Rule (plain English) | Weight |
|---|---|---|
| 1 | All four letters stay on one hand and use only the pinky and ring fingers. | 1.0 |
| 2 | All four letters stay on one hand and the row movement reverses direction *twice* (a zig-zag/wave: up-down-up or down-up-down). Penalty depends on the size of the smallest row jump in the zig-zag. | 1.0 (jump of 1), 2.0 (jump of 2+) |
| 3 | All four letters fully alternate hands on every keystroke. | 1.0 |

## 5. 5-gram motion costs (order 5)

Applied to every 5 consecutive characters.

| # | Rule (plain English) | Weight |
|---|---|---|
| 1 | All five letters are typed by the *same hand* — no hand alternation at all across the whole sequence. | 3.0 |
| — | Any sequence with at least one hand alternation. | 0.0 |

## Order weights

| Order | Config key | Value |
|---|---|---|
| 1 (unigram) | `weights.1` | 1.0 |
| 2 (bigram) | `weights.2` | 1.0 |
| 3 (trigram) | `weights.3` | 1.0 |
| 4 (4-gram) | `weights.4` | **12.0** |
| 5 (5-gram) | `weights.5` | **12.0** |

Orders 1-3 are left at 1.0 (no-op). Orders 4 and 5 are deliberately
weighted far above 1.0 -- this is not a typo or a mistuned correction
factor, and it's worth explaining why before anyone "fixes" it back to
1.0.

**The reasoning:** comparing this project's GA-optimized layouts against
14 well-known reference layouts (`compare_layouts.py`) showed a broad
plateau of layouts scoring within roughly 1% of each other on orders 1-3
(unigram reach + bigram/trigram motion) before a clear gap opened up
toward the worse layouts -- e.g. `mod`, `mod_mirrored`, `beakl15`, and
several of this project's own GA runs were nearly indistinguishable on
those orders alone. On a plateau like that, there is room to additionally
select *among* the near-tied candidates for a property that orders 1-3
can't see: whether they also tend to produce a 4-key run that fully
alternates hands on every keystroke (4-gram rule #3) or a 5-key run that
never alternates hands at all (5-gram rule #1) -- both comparatively rare,
specific motion patterns. A small weight (1.0) lets these rules vanish
into rounding error: a normalized order-4/5 component is typically only
~0.01-0.04 against a typical order 1-3 total of ~0.45, so it has almost no
say in which layout wins. Multiplying by 12 inflates that into a
comparable or larger share of the total fitness -- in practice, a swing
of roughly 0.18-0.39 (order 4) and 0.0-0.18 (order 5) was observed across
the comparison layouts, easily large enough to flip the ranking. That's
the intended effect: at this magnitude, orders 4 and 5 stop behaving like
a small refinement and start behaving like a soft *constraint* (similar in
spirit to `constraints.py`, but continuous and frequency-weighted instead
of binary), pruning layouts that hit these specific patterns often, while
still leaving plenty of otherwise-different layouts in contention.

**How 12 was chosen:** by inspecting how much it reordered a fixed set of
existing layouts using `fitness_components()`/`compare_layouts.py`
*without* running a new GA search -- a deliberately aggressive, exploratory
starting point, not a value derived from typing-speed data or any formal
optimization. If you're tuning this further: a value near 1.0 makes
orders 4/5 negligible; pushing far above 12 risks orders 4/5 dominating
the *entire* fitness, trading away genuine unigram/bigram typing
efficiency just to avoid a handful of rare patterns -- watch
`fitness_components()` on candidate layouts to make sure orders 1-2 still
account for a healthy majority of the total before going higher.

---

# Analysis: do the rules make sense?

## Rules that are well-supported by typing ergonomics

- **Inner roll cheap (1.0), outer roll expensive (3.0)** (bigram #6a/6b).
  Matches standard ergonomic-layout literature (Colemak, Carpalx): rolling
  fingers inward toward the palm is more natural than rolling outward.
- **Same-finger costs scale with distance and are worse for weak fingers**
  (bigram #1, #4). Consistent with virtually every keyboard effort model.
- **Side-swipe / down-swipe treated as cheap exceptions** (bigram #2, #3).
  Sensible — these are recognized low-effort motions; charging them at the
  full same-finger rate would over-penalize common, easy patterns.
- **Different-hand bigram cost is flat (2.0), independent of distance**
  (bigram #5). A reasonable simplification: there's no shared kinetic chain
  between hands, so exact key distance matters far less than for same-hand
  transitions.
- **Pinky+ring-only run penalties** (trigram #2, 4-gram #1) and the
  **pinky-ring-middle downward / ring-middle-index upward penalties**
  (trigram #5, #6) target real, well-known awkward motions: sustained or
  specifically-ordered reliance on the weakest fingers.
- **The trigram/4-gram "fully alternates hands" penalties (1.0 each)**
  are not modeling raw motion effort -- a hand-alternating bigram isn't
  obviously more *physically* effortful than a same-hand one, and
  mainstream ergonomics generally treats moderate alternation as good
  (it lets each hand prepare its next stroke while the other executes).
  These rules model something different: heavy, *constant* alternation
  (switching hands on literally every keystroke for 3-4 keys running)
  removes any rolling rhythm and forces tight inter-hand timing
  synchronization, which is exactly the kind of coordination overhead
  that produces typing errors at speed -- and the cost incurred fixing an
  error (backspacing, retyping) is real effort this project's
  effort-per-keystroke model has no other way to represent. That's a
  plausible mechanism, not something validated against this project's
  data or cited from a specific study, but it's a deliberate choice to
  fill a real gap (error-correction cost) rather than a double-count of
  motion effort already charged elsewhere -- see bigram rule #5 above:
  the flat different-hand bigram cost doesn't distinguish an "easy"
  cross-hand pairing from an awkward one (no inner/outer-roll-style
  shape sensitivity for hand-alternating pairs), so these rules are not
  redundant with anything at the bigram level. This is *why* the 5-gram
  rule pulls in the seemingly opposite direction (penalizing *zero*
  alternation, not excess alternation): it's targeting a different
  failure mode (one hand doing all the work, fatigue) with the same tool
  (a fitness penalty), not contradicting the trigram/4-gram rules' logic.

## Rules and design choices still worth scrutinizing

- **The cross-hand "shape" the bigram cost ignores (rule #5 above) could
  in principle be modeled** -- e.g. some specific finger pairings across
  hands probably feel more natural than others, mirroring the inner/outer
  roll distinction same-hand pairs already get. This was deliberately
  *not* added: the trigram/4-gram alternation penalties already exist to
  address the closely related concern of heavy-alternation error risk
  (see above), so adding shape-sensitivity to the bigram cost as well
  would mostly be solving an already-mitigated problem at the cost of
  meaningfully more code. Worth revisiting only if evidence suggests the
  current penalties are missing something the shape-aware version
  wouldn't.
- **Pinky/ring-only and hand-alternation facts are charged at more than
  one order** (bigram pinky/ring pairs, trigram/4-gram pinky-ring runs;
  bigram different-hand cost, trigram/4-gram full-alternation runs). This
  is the intended "repetitive motion compounds" design (see the file
  intro), but it does mean these specific motions have more total
  influence on the fitness sum, order-for-order, than motions that are
  only visible at a single order (like the direction-reversal rules). If
  that turns out to skew the optimizer too strongly towards avoiding
  pinky/ring or hand-switching specifically, the `weights` for orders 3/4
  are the lever to pull, rather than editing these per-rule constants.
- **The 3-finger directional penalties cover only two hand-written cases**
  (pinky→ring→middle downward, ring→middle→index upward). Other equally
  awkward finger-order/direction combinations (e.g. middle→ring→pinky
  upward) go unpenalized simply because nobody enumerated them — a
  coverage gap, not a wrong call on what is covered.
- **The trigram "no roll" penalty (1.0) is small relative to its sibling**
  (non-monotonic-rows tops out at 5.0). Broken rolls/redirects are usually
  considered one of the *more* disruptive patterns in established
  typing-effort models (e.g. Carpalx weighs "roll reversal" heavily). A
  weight of 1.0 here may understate how costly redirects actually are.
- **The per-key reach-effort grid has a structural oddity inherited from
  R LEGS**: the top row's leftmost/rightmost keys (cost 8, the maximum in
  the whole grid) are assigned to the *ring* finger in `FINGER_MAP`, not
  the pinky — no top-row key is ever reached by the pinky in this model.
  Worth double-checking against whatever physical keyboard the effort
  numbers were originally measured on.
- **None of the per-rule constants (1.0, 2.0, 3.0, 5.0, ...) are
  empirically derived** — they're carried over from the R LEGS source
  largely unchanged. Ablation runs (toggle one rule at a time, rerun the
  GA, compare resulting layouts/fitness) are the natural next step if
  these need validating against real typing data.

## Bottom line

Every rule from the original R LEGS-derived heuristics is intact, including
the ones that re-evaluate a fact also visible at a lower order (pinky/ring
runs, hand alternation) — that overlap is treated as a deliberate model of
cumulative/repetitive-motion effort, not a bug. The trigram/4-gram
alternation penalties specifically also stand in for an error-correction
cost (heavy alternation risking more mistakes at speed) that a pure
per-keystroke effort tally has no other way to represent, and that
penalty is deliberately left as a flat per-window cost rather than also
making the bigram cost shape-sensitive to which fingers pair up across
hands -- the alternation penalty already covers the concern that would
motivate that extra complexity. The per-order `weights` in `config.yaml`
are the supported way to rebalance how much each order contributes to the
total without touching the cost functions themselves — currently used to
deliberately push orders 4/5 (weight 12.0 each) into acting like a soft
constraint against rare full-hand-alternation / full-hand-monopoly
motion, on top of orders 1-3 left at their neutral 1.0.
