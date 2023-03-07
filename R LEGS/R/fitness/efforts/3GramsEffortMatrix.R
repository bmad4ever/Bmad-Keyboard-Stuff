# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 20/04/2022


source("R/fitness/QueriesAndDefinitions.R")

# ###################################################################
# Motions costs/penalties
# ###################################################################

#  when using same hand
trigram.costs.same_finger_no_swipes <- 2  # TODO not implemented, but should be extremely rare
trigram.costs.pinky_ring_middle_going_downward_penalty <- 2  # only if pinky to middle has 2 rows difference
trigram.costs.ring_middle_index_going_upward_penalty <- 2  # only if ring to index has 2 rows difference
trigram.costs.only_pinky_and_ring_used_penalty <- 3  # if this is found, no roll is ignored
trigram.costs.no_roll_penalty <- 1  # applied when switching the direction of a roll (prefer switching hands over repeated pronation/supination)
trigram.costs.non_monotonic_rows_penalties <- c(1, 2, 5)  # depending on sum of row differences with respect to the 2nd finger in the sequence which can be 2,3 or 4

#  when alternating hands 2x (a single sweeping motion is prefareble)
trigram.costs.hand_swap_2x  <- trigram.costs.no_roll_penalty


# auxiliary functions

trigram.costs.compute_non_monotonic_rows_penalty <- function(keys_rows)
  trigram.costs.non_monotonic_rows_penalties[abs(keys_rows[1]-keys_rows[2]) + abs(keys_rows[2]-keys_rows[3]) - 1]

# ###################################################################
# Trigram Motion Cost Functions
# ###################################################################

trigram.trigram_cost <- function(key1, key2, key3) {
  sum <- 0


  if (areSameHand(key1, key2) && areSameHand(key2, key3)) {
    # ALL KEYS PRESSED W/ 1 HAND

    # Get fingers
    fingers <- c(finger_map[key1], finger_map[key2], finger_map[key3])

    # Get keys' positions
    keys_rows <- c(getKeyPosRow(key1), getKeyPosRow(key2), getKeyPosRow(key3))
    keys_columns <- c(getKeyPosColumn(key1), getKeyPosColumn(key2), getKeyPosColumn(key3))

    # Check if only one finger appears
    if (length(unique(fingers)) == 1) {
      # TODO check for swipes
      #  low priority, should be uncommon if 2Gram is working as intended.
      #  don't remove if, avoids entering next condition.
    }
    # Check if only the pinky and ring fingers appear
    else if (all(fingers %in% c(finger['left_pinky'], finger['left_ring'])) ||
              all(fingers %in% c(finger['right_pinky'], finger['right_ring'])) ) {
      sum <- sum + trigram.costs.only_pinky_and_ring_used_penalty
    }
    # Check the direction of movement
    else if (is.unsorted(keys_columns) && is.unsorted(rev(keys_columns))){
        # There is a direction change
        sum <- sum + trigram.costs.no_roll_penalty
    }
    # Check if key rows are non monotonic && and all fingers are used
    if ( length(unique(fingers)) == 3 && is.unsorted(keys_rows) && is.unsorted(rev(keys_rows))) {
      sum <- sum + trigram.costs.compute_non_monotonic_rows_penalty(keys_rows)
    }
    # Check if rows decrease from pinky to middle finger
    if (is_pinky_raw(fingers[1]) && is_ring_raw(fingers[2]) && is_middle_raw(fingers[3]) && keys_rows[1] + 1 < keys_rows[3]) {
      sum <- sum + trigram.costs.pinky_ring_middle_going_downward_penalty
    }
     # Check if rows increase from pinky to middle finger
    if (is_ring_raw(fingers[1]) && is_middle_raw(fingers[2]) && is_index_raw(fingers[3]) && keys_rows[1] > 1 + keys_rows[3]) {
      sum <- sum + trigram.costs.ring_middle_index_going_upward_penalty
    }

  }
  else if(!areSameHand(key1, key2) && !areSameHand(key2, key3)){
    # HAND ALTERNATION 2X
    sum <- sum + trigram.costs.hand_swap_2x
  }

  return(sum)
}

# ###################################################################
# Pre compute all possible values
# ###################################################################

trigram.pre_computed_costs <- array(rep(0, 30*30*30), c(30, 30, 30));
  for(i1 in 1:30)
  for(i2 in 1:30)
  for(i3 in 1:30)
    trigram.pre_computed_costs[i1,i2,i3] <- trigram.trigram_cost(i1, i2, i3)