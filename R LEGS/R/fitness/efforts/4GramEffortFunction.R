# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 20/04/2022

library(hash)
source("R/fitness/QueriesAndDefinitions.R")

# ###################################################################
# Motions costs/penalties
# ###################################################################

# same hand
fourgram.costs.double_vertical_direction_change <- c(1,2) # index selected using the minimum vertical distance, add the extra work, not all the work
fourgram.costs.only_pinky_and_ring_used_penalty <- 1 # note that a penalty is already used in 3gram, add the extra to that, not all the effort

# 3 hand changes
trigram.costs.hand_swap_3x  <- 1

# ###################################################################
# Fourgram Motion Cost Functions
# ###################################################################

fourgram.fourgram_cost <- function(key1, key2, key3, key4) {
  sum <- 0

  if (areSameHand(key1, key2) && areSameHand(key2, key3) && areSameHand(key3, key4))
  {
      # ALL KEYS PRESSED W/ 1 HAND

      # Get fingers
      fingers <- c(finger_map[key1], finger_map[key2], finger_map[key3], finger_map[key4])

      # Get keys' positions
      keys_rows <- c(getKeyPosRow(key1), getKeyPosRow(key2), getKeyPosRow(key3), getKeyPosRow(key4))
      #keys_columns <- c(getKeyPosColumn(key1), getKeyPosColumn(key2), getKeyPosColumn(key3), getKeyPosRow(key4))

      if (all(fingers %in% c(finger['left_pinky'], finger['left_ring'])) ||
              all(fingers %in% c(finger['right_pinky'], finger['right_ring'])) )
      {
        sum <- sum + fourgram.costs.only_pinky_and_ring_used_penalty
      }

      rows_diff <- diff(keys_rows)
      if(
        rows_diff[1] > 0 && rows_diff[2] < 0 && rows_diff[3] > 0 ||
        rows_diff[1] < 0 && rows_diff[2] > 0 && rows_diff[3] < 0
      )
      {
        sum <- sum + fourgram.costs.double_vertical_direction_change[
          min(abs(rows_diff[rows_diff != 0]))
        ]
      }
  }
  else if (!areSameHand(key1, key2) && !areSameHand(key2, key3) && !areSameHand(key3, key4))
  {
    # 3 HAND ALTERNATIONS
      sum <- sum + trigram.costs.hand_swap_3x
  }

  return(sum)
}

fourgram.fourgram_cost(21, 29, 23, 4)


# ###################################################################
# Pre compute all possible values  *cheat using a list of index that have a value*
# ###################################################################

# Create a new hashset object and add the key-value pairs
fourgram.hashmap <- hash()

# Create a vector of key-value pairs
for(i1 in 1:30)
for(i2 in 1:30)
for(i3 in 1:30)
for(i4 in 1:30) {
  computed_effort <- fourgram.fourgram_cost(i1,i2,i3,i4)
  if(computed_effort > 0){
      keys_vector <- c(i1, i2, i3, i4)
      fourgram.hashmap[[paste(keys_vector, collapse = "")]] <- computed_effort
  }
}

fourgram.pre_computed_costs <- function(key1, key2, key3, key4){
  stored_effort <- fourgram.hashmap[[paste(c(key1, key2, key3, key4), collapse = "")]]
  if(stored_effort == NULL)
    return(0)
  return(stored_effort)
}



testIt <- function(){
   print(fourgram.hashmap[[paste(c(11, 12, 13, 14), collapse = "")]])
   print(fourgram.hashmap[[paste(c(19, 20, 18, 16), collapse = "")]])
   print(fourgram.hashmap[[paste(c(21, 2, 23, 4), collapse = "")]])
   print(fourgram.hashmap[[paste(c(12, 18, 13, 17), collapse = "")]])
   print(fourgram.hashmap[[paste(c(11, 12, 21, 22), collapse = "")]])
}