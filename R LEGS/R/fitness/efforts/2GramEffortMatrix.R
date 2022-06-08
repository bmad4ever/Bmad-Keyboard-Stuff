# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 20/04/2022

source("R/fitness/QueriesAndDefinitions.R")

# ###################################################################
# Motions costs/penalties
# ###################################################################

# cost of using different hands for bigram
bigram.costs.differentHand <- 2

# costs for inward and outward rolls
bigram.costs.innerRoll <- 1
bigram.costs.outerRoll <- 3

# effort per row difference
# ... maybe this could be more granular?
bigram.costs.perRowDifWhenUsingDiffentFingers <- 1

# The cost of using the same finger to type
#   costs for each finger respectively: pinky, ring, middle, index.
bigram.costs.sameFingerSameKeyCosts <- c(4  , 3  , 2.5  , 2.5  )
bigram.costs.sameFingerNoSwipeCosts <- c(5  , 4  , 3.5  , 3.5  )
bigram.costs.sameFingerNoSwipeCost <- function(key1, key2)
  bigram.costs.sameFingerNoSwipeCosts[ignoreHand(finger_map[key1])] * keysDistE(key1, key2)

# Swiping motion costs. (check swipe detection functions below)
bigram.costs.sideSwipe <- 2
bigram.costs.downSwipe <- 2

#' Penalties for using pinky and ring finger for a bigram.
#' pinky x ring combo penalty depends on the row diff,
#' first position equals 0 row difference and last equal 2
bigram.costs.pinky_with_ring_penalty <- c(1,1,3)

#' Penalties for streaching the index finger over one colunm when using middle finger for the other key
#' middle x streatched index combo penalty depends on the row diff,
#' first position equals 0 row difference and last equal 2
bigram.costs.middle_with_index_stretch_penalty <- c(2,2,3)

# ###################################################################
# Auxiliary functions
# ###################################################################

isDownwardMovement <- function(rowDif) rowDif<0
isUpwardMovement <- function(rowDif) rowDif>0

#' Checks if the motion is an inward roll, under the suposition that the same hand is used for both keys
#' @param leftHand indicates which hand executes the motion (true = left hand)
isInwardRoll <- function(key1_pos, key2_pos, leftHand)
  getColDifferenceSameHand(key1_pos, key2_pos, leftHand)<0

#' Check if bigram is using little and ring finger.
bigram.costs.usesLittleAndRing <- function (key1_pos, key2_pos)
  return(
    areTheseFingersUsed2(c(finger['pinky'], finger['ring']), hand['left'], key1_pos,key2_pos)
    || areTheseFingersUsed2(c(finger['pinky'], finger['ring']), hand['right'], key1_pos,key2_pos)
  )

isPossibleToIndexFingerSideSwipe <- function (key1_pos, key2_pos, isLeftHand, rowDifference){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    is_index(key1_pos) # uses index
     && isHomeRow(key2_pos) # only consider swipes that go into the homerow
      && !isUpwardMovement(rowDifference) # check if the movement is not from a lower row, downward diagonal is accepted
      && # check that keys are adjacent and the movement is towards the center of the keeb
      getColDifferenceSameHand(key1_pos, key2_pos, isLeftHand)==1
    )
}

# I am not sure if this is doable...
# there might be someone who does it just like I do it with the index finger.
# I don't check the diagonal as a possible movement.
isPossibleToRingFingerSideSwipe <- function (key1_pos, key2_pos, isLeftHand){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    is_ring(key1_pos) # uses ring finger
     && isHomeRow(key2_pos) # only consider swipes that go into the homerow
      && isHomeRow(key1_pos) # do not accept diagonal movements
      &&  # check that keys are adjacent and the movement is towards the center of the keeb
      getColDifferenceSameHand(key1_pos, key2_pos, isLeftHand)==-1
    )
}

isPossibleToVerticalSwipe <-  function (key1_pos, key2_pos,rowDifference){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    rowDifference == -1 #moves only one key down
    && !is_pinky(finger_map[key1_pos])  #exclude little finger swipes
    && getAbsColDifference(key1_pos, key2_pos) == 0  # check if collumn is the same
  )
}


bigram.costs.usesIndexMiddleStretch<- function (key1_pos, key2_pos)
  return(
    (
        areTheseFingersUsed( c(finger['left_middle'] , finger['left_index'] ) ,key1_pos, key2_pos )
     || areTheseFingersUsed( c(finger['right_middle'], finger['right_index']) ,key1_pos, key2_pos )
    )
    && getAbsColDifference(key1_pos, key2_pos)>1
  )


# ###################################################################
# Bigram Motion Cost Functions
# ###################################################################

bigram.bigram_cost <- function(key1_pos, key2_pos){
  key1_OnLeftHand <- isLeftHand(key1_pos)
  rowDiff <- getRowDifference(key1_pos,key2_pos)

  if(isSameFinger(key1_pos, key2_pos)){
    #Same finger used to type bigram

    #is the same key repeated.
    if(isSameKey(key1_pos, key2_pos))
      return(bigram.costs.sameFingerSameKeyCosts[ignoreHand(finger_map[key1_pos])])

    # check horizontal swipes
    if(isPossibleToIndexFingerSideSwipe(key1_pos, key2_pos,key1_OnLeftHand,rowDiff))
      return(bigram.costs.sideSwipe)

    # Uncomment if it is relevant to you
    #if(isPossibleToRingFingerSideSwipe(key1_pos, key2_pos,key1_OnLeftHand))
    #  return(bigram.costs.sideSwipe)

    # check vertical swipe
    if(isPossibleToVerticalSwipe(key1_pos, key2_pos,rowDiff))
      return(bigram.costs.downSwipe)

    #non swipe movement
    return(bigram.costs.sameFingerNoSwipeCost(key1_pos, key2_pos))
  }

  # Different fingers used

  if(key1_OnLeftHand != isLeftHand(key2_pos))
    return(bigram.costs.differentHand) #uses different hands

  # else, uses same hand

  abs_rowDiff <- abs(rowDiff)
  cost <- abs_rowDiff * bigram.costs.perRowDifWhenUsingDiffentFingers

  if(isInwardRoll(key1_pos, key2_pos, key1_OnLeftHand))
    cost <- cost + bigram.costs.innerRoll # inward roll
  else
    cost <- cost + bigram.costs.outerRoll # ourward roll

  if(bigram.costs.usesLittleAndRing(key1_pos,key2_pos))
    cost <- cost + bigram.costs.pinky_with_ring_penalty[abs_rowDiff+1]

  if(bigram.costs.usesIndexMiddleStretch(key1_pos, key2_pos))
    cost <- cost + bigram.costs.middle_with_index_stretch_penalty[abs_rowDiff+1]

  return(cost)
}



# ###################################################################
# Pre compute all possible values
# ###################################################################

bigram.pre_computed_costs <- matrix(0,nrow = 30, ncol = 30)
  for(fp in 1:30)#1st letter position
  for(sp in 1:30)#2nd letter position
    bigram.pre_computed_costs[fp,sp] <- bigram.bigram_cost(fp, sp)