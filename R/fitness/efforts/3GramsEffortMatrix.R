# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 20/04/2022

# TODO to be implemented

#  when using same hand
# penalty: pinky -> ring -> middle if row goes down instead of neutral or up
# penalty: switch the direction of a roll (prefer switching hands over repeated pronation/supination)
# penalty: pressed keys positions (not pressing order!) vertical positions from left to right change in a non monotonic fashion
# penalty: only pinky and ring fingers used (tension build up)

# resonable but not applicable (rare occurance)
# penalty: 3 presses with same finger penalty


trigram.trigram_cost <- function(key1_pos, key2_pos, key3_pos){
  isKey1OnLeftHand <-  isLeftHand(key1_pos)
  onSingleHand <- isKey1OnLeftHand == isLeftHand(key2_pos) == isLeftHand(key3_pos)

  if(!onSingleHand)
      return(0)

  return(0)
}