# PyGA_Keeb: Keyboard Layout Optimization Using Genetic Algorithms

A Python re-implementation (Python 3.9) of the keyboard-layout GA, 
replacing the deprecated V1 motion-cost approach from
`R LEGS/` with absolute n-gram counts derived from a local corpus.

## Layout

- `corpus/` — text corpus used to derive n-gram counts (see "About the
  corpus" below for what's in it and why).
- `R LEGS/` — read-only R reference implementation (do not modify).
- `PyGA_Keeb/` — all Python code, configuration, data, and results.

## Setup

```bash
cd PyGA_Keeb
python3.9 -m pip install -r requirements.txt
```

## Usage

1. **Build n-gram counts from the corpus:**

   ```bash
   python3.9 corpus_analysis.py --corpus ../corpus --max-order 5 --output-dir data
   ```

   Writes `data/ngram_counts.json` with absolute unigram..5-gram counts
   (26 letters + `. , ' ;`). `config.yaml`'s default
   weights assume order-5 data exists (`weights.5: 12.0` is a no-op if
   you build with a lower `--max-order` and order 5 is simply absent from
   the data) -- the CLI's own `--max-order` default is still 4 for
   backward compatibility, so don't omit this flag.

2. **Run the GA:**

   ```bash
   python3.9 ga_optimizer.py --config config.yaml --ngram-data data/ngram_counts.json
   ```

   GA hyperparameters, top-N filtering thresholds, and optional per-order
   fitness weights are all set in `config.yaml` (see "Notes on the fitness
   function" below for why those weights are a tuning convenience, not a
   correctness requirement). `fitness.allow_swipe_motions` (default
   `true`) controls whether same-finger "swipe" transitions are treated as
   cheap -- set it to `false` if your target keyboard doesn't support
   sliding a finger across keycaps (most physical keyboards don't); see
   `config_no_swipe.yaml` for a ready-to-use example and COST_RULES.md for
   the full rationale. Each run writes a timestamped folder under
   `results/` containing `best_layout.txt`, `log.json` (full history,
   config, weights, and the `allow_swipe_motions` setting used), and
   `fitness_history.png` (best/average fitness per generation).

3. **Run the sanity tests:**

   ```bash
   python3.9 -m unittest discover -s tests -v
   ```

## About the corpus

Fitness is entirely driven by `corpus/`'s n-gram statistics — there's no
hardcoded English-language model, so whatever text you point
`corpus_analysis.py` at directly determines what "low effort" means.

Computing **absolute** n-gram counts directly
from a corpus rather than relying on an external frequency database 
wasn't a stylistic preference: several readily-available frequency
sources turned out not to fit this project's needs -- some only
publish relative frequencies *within* a given n-gram order rather than
absolute counts, which doesn't support the cross-order normalization this
project relies on (each order's component needs a comparable absolute
denominator, see "Notes on the fitness function" below); and some omit
punctuation entirely. Computing counts directly from a plain text
corpus sidesteps both problems by construction.

The corpus in this repo right now is a mix of:

- a handful of small markdown files, copied in from an unrelated external
  project purely as a convenient source of real technical prose -- they
  aren't part of this project and won't be tracked in this repo
- `wiki/` — programming/CS-related Wikipedia articles (technical, formal,
  third-person prose)
- `hn_comments/` — Hacker News comments (casual, conversational, tech-
  adjacent forum writing)
- `letters/` — public-domain personal correspondence (first-person,
  contraction-heavy, conversational prose), added because the
  Wikipedia/markdown material skewed almost entirely formal and
  third-person, underrepresenting how people actually type day-to-day

Being free to use *any* plain-text corpus also means you can point this
at a sample of your own writing (emails, chat logs, notes, commit
messages) instead, so the resulting layout reflects your own typing
patterns specifically -- a nice bonus of the corpus-driven design, though
not the reason that design was chosen (see above). Drop your text files
anywhere under `corpus/` (subdirectories are scanned recursively) and
rerun `corpus_analysis.py`.

## Modules

| File                  | Purpose                                                              |
|------------------------|-----------------------------------------------------------------------|
| `keyboard.py`          | 30-key grid geometry, finger map, distance helpers (ported from R LEGS `QueriesAndDefinitions.R`). |
| `costs.py`             | Bigram/trigram/4-gram/5-gram motion-cost functions (ported from R LEGS `R/fitness/efforts/`, V1 excluded). |
| `corpus_analysis.py`   | Scans the corpus and writes absolute n-gram counts.                  |
| `fitness.py`           | Combines per-key reach effort and n-gram motion costs into a single normalized fitness score, with an optional per-order weight (default 1.0, see COST_RULES.md). |
| `constraints.py`       | Optional soft-penalty constraints (fixed positions, vowels on one hand, punctuation in corners), ported from R LEGS `R/fitness/constraints/`. |
| `ga_optimizer.py`      | Custom GA (tournament selection, order crossover, swap mutation, elitism, adaptive mutation) with matplotlib convergence plotting. |
| `tests/test_sanity.py` | N-gram counting correctness, fitness monotonicity, GA-vs-baseline comparison, reproducibility. |

## Optional constraints

Ported from R LEGS' soft-penalty constraints (`R/fitness/constraints/`),
`PyGA_Keeb/constraints.py` lets you bias the GA towards layouts that satisfy
extra requirements, without making them strictly mandatory: each violated
constraint just adds its configured `weight` to the fitness total (lower is
better), the same `(1 - satisfied) * weight` design R LEGS uses. Four
constraints are available:

| Constraint | Config key | What it does |
|---|---|---|
| Fixed key positions | `fixed_positions` | Forces given characters onto given 0-indexed key positions (e.g. pin `e` to the home row). |
| Vowels on one hand | `vowels_side` | Forces `a, e, i, o, u` onto the left or right hand. |
| Punctuation in corners | `non_letters_outer_corners` | Forces all non-letter characters into the 4 outer-corner keys (positions 0, 9, 20, 29). |
| Punctuation in extended corners | `non_letters_extended_corners` | Models a split keyboard (left half = columns 0-4, right half = columns 5-9): forces all non-letter characters into the 4 outer corners (facing the device's outer edges) *plus* the 4 inner corners (facing the split gap), except the 2 bottom outer corners -- positions (0, 4, 5, 9, 24, 25). |

To run with constraints, add a `constraints:` section to your config (see
the commented-out example at the bottom of `PyGA_Keeb/config.yaml`), then:

```bash
python3.9 ga_optimizer.py --config my_config.yaml --run-name my-label
```

`--run-name` just adds a label to the `results/run-<timestamp>-<label>/`
folder name; it's optional.

This repo includes four ready-to-use example configs and their results:

```bash
python3.9 ga_optimizer.py --config config_fixed_e_home.yaml --run-name fixed-e-home
python3.9 ga_optimizer.py --config config_vowels_left.yaml --run-name vowels-left
python3.9 ga_optimizer.py --config config_punct_corners.yaml --run-name punct-corners
python3.9 ga_optimizer.py --config config_extended_corners_vowels_left.yaml --run-name extcorners-vowels-left
```

Results (200 population, 600 generations, seed 42, weight 0.2 per
constraint, orders 4/5 weighted 12x -- see "Notes on the fitness function"
below; corpus now includes ~120k words of programming-related Wikipedia
text plus ~123k words of conversational/first-person text -- Hacker News
comments and personal letters, added to counter the original corpus's
all-technical-prose skew. All constraints came out fully satisfied, i.e.
0 penalty. These fitness values are *not* comparable to earlier numbers
in this file's history -- the metric's scale changed along with the
corpus and weights):

| Run | Fitness | Layout (rows top→bottom) |
|---|---|---|
| unconstrained baseline | 0.5832 | `jbnpf'gdxz` / `uati.meor,` / `qvwsykclh;` |
| `fixed-e-home` (`e` pinned to position 13) | 0.6011 | `xulo.;tngj` / `'riembsafv` / `zdh,ywcpkq` |
| `punct-corners` (`.`,`,`,`'`,`;` in the 4 outer corners) | 0.6056 | `;vagqkomj,` / `whntpuirel` / `.xscfybdz'` |
| `extcorners-vowels-left` (punctuation in the 6 extended-corner keys **and** vowels on the left hand, combined) | 0.6065 | `,xmoj'gcy;` / `uvrebltnsp` / `zdia.khfwq` |
| `vowels-left` (a,e,i,o,u on left hand) | 0.6099 | `xzau;jhfkq` / `'oerlpstcm` / `bd.iyvnwg,` |

Each added constraint costs more here than under the old 1.0-weighted
scheme, since orders 4/5 are now a much larger share of the total fitness
and constraints compete with them for the same "avoid rare bad patterns"
budget. Stacking two constraints (`extcorners-vowels-left`) costs more
than either alone, as expected, but the GA still finds a fully-satisfying
layout without the search collapsing.

## Comparing layouts

`PyGA_Keeb/compare_layouts.py` scores any set of layout files with the same
fitness function and corpus n-gram data, ignoring optional constraints, and
plots a sorted, zoomed dot chart (axis cropped to the main cluster, with
distant outliers pushed to a marked off-scale edge so close-scoring layouts
stay readable). With no arguments it auto-discovers every
`results/run-*/best_layout.txt` from this project plus every layout in
`R LEGS/layouts/*.txt` (translating R LEGS' `-` 30th character to this
project's `'`):

```bash
python3.9 compare_layouts.py
```

This prints a ranked fitness table and writes
`results/layout_comparison.png`. Use `--layout NAME=PATH` (repeatable) to
compare a specific subset instead of the auto-discovered set.

Each layout also gets a second, grayed-out dot directly below its main one:
the same layout's fitness recomputed with orders 4/5 forced to weight 0 (a
thin gray line connects the pair). The horizontal gap between a layout's
main dot and its gray reference dot is a direct visual read of how much
the 12x order-4/5 weighting is currently moving that layout's score and
ranking -- e.g. `r_legs/4_10_16` scores *better* than this project's own
unconstrained GA run on orders 1-3 alone, but worse overall once orders
4/5 are weighted in.

## Notes on the fitness function

Each n-gram order's raw cost is normalized to `[0, 1]` by dividing by
`total_chars * max_cost_for_order`, where `total_chars` is the corpus's
total character count (the unigram total) — the *same* denominator for
every order — and then multiplied by an optional per-order weight from
`config.yaml` (default 1.0, i.e. a no-op if omitted) before being summed.
`costs.py`'s trigram/4-gram cost functions deliberately re-evaluate some
facts also visible at a lower order (e.g. a sustained pinky/ring-only run,
or a sequence that fully alternates hands) as a way of modeling
cumulative/repetitive-motion and higher-order hand-motion effort that
compounds beyond any single pairwise transition — that overlap is
intentional, not a bug. Because the same motion can therefore be charged
at more than one order, the per-order `weights` are the supported way to
rebalance how much influence each order has on the total, without editing
the constants inside any cost function.

Currently `config.yaml` weights orders 4 and 5 at **12.0** (vs. 1.0 for
orders 1-3) — a deliberately aggressive, near-prohibitive multiplier
chosen because comparing layouts showed many of them scoring within ~1%
of each other on orders 1-3 alone (a broad plateau, not one sharp
optimum), leaving room to additionally select against rare patterns
orders 1-3 can't see: a 4-key run that fully alternates hands every
keystroke, or a 5-key run that never alternates hands at all. At 12x,
these stop being a rounding error and start acting like a soft, frequency-
weighted *constraint* similar in spirit to `constraints.py`. This was
chosen by inspecting how much it reordered existing layouts, not derived
from typing-speed data — see `PyGA_Keeb/COST_RULES.md`'s "Order weights"
section for the full reasoning, the numbers behind it, and what to watch
for if you tune it further. See that same file for every rule in plain
English plus an analysis of which ones hold up and which are still
hand-picked guesses, and `costs.py`'s module docstring for the cost-design
rationale.

An even earlier version of the normalization divided each order's raw
cost by *that order's own* (possibly top-N-truncated) occurrence count
instead of `total_chars`. That produces a per-occurrence average within
each order's own sample rather than a per-character contribution — two
orders end up on incomparable scales, so combining them no longer
approximates total typing effort. That was exactly the flaw in R LEGS'
original V1 fitness function that this project was meant to fix, so it
was corrected once identified. See `config.yaml` for the top-N thresholds.

## Adapting this for your own keyboard

This project models a specific 3x10 grid (30 keys, row-major: positions
0-9 are the top row, 10-19 the home row, 20-29 the bottom row) with a
fixed 8-finger assignment. If your physical keyboard differs (different
finger assignment, a split layout, different per-key reach difficulty),
two files are where you'd change it -- both are plain Python tuples read
fresh on every run, no caching or regeneration step needed:

- **Finger assignment** — `PyGA_Keeb/keyboard.py`'s `FINGER_MAP` tuple (30
  ints, one per key position, row-major). Values are 1=left pinky,
  2=left ring, 3=left middle, 4=left index, 5=right index, 6=right middle,
  7=right ring, 8=right pinky (see the `FINGER_LEFT_*`/`FINGER_RIGHT_*`
  constants just above it). Editing this changes which finger every motion
  cost rule in `costs.py` (same-finger costs, rolls, pinky/ring penalties,
  hand-alternation rules, etc.) attributes each key to.
- **Per-key reach effort** — `PyGA_Keeb/fitness.py`'s `POSITION_EFFORT`
  tuple (30 floats, same row-major position numbering; lower = easier to
  reach). This is the unigram (order 1) cost table — see COST_RULES.md
  section 1. It's independent of `FINGER_MAP`; you can have an
  easy-to-reach key on a hard-to-use finger or vice versa.

Both tuples must stay exactly 30 entries long (`assert len(...) == N_KEYS`
in each file will fail loudly otherwise). `keyboard.py`'s `key_row`/
`key_col` helpers convert a position index to/from row/column if you'd
rather reason in grid coordinates than flat indices while editing these.
Changing the number of keys (not just their finger/effort assignment) is
a bigger change than these two tuples — `CHARACTERS` in `keyboard.py`,
`N_ROWS`/`N_COLS`, and every cost function in `costs.py` that assumes a
3-row grid would need revisiting too.

For the *split-keyboard* corner geometry used by the optional
`non_letters_extended_corners` constraint (`constraints.py`'s
`INNER_CORNERS`/`OUTER_CORNERS`), see "Optional constraints" above — that
assumes the split falls between columns 4 and 5; adjust those tuples if
your split point differs.
