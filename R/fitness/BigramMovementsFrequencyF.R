# Title     : Bigram/Motion Frequency Fitness
# Objective : Estimate the effort of a layout with respect to
#               bigram frequency and respective input motion effort
# Created by: Bruno
# Created on: 27/06/2021


finger_map <- read.table("data/finger_map.txt", header=FALSE, sep=" ")
finger_map <- as.vector(t(finger_map))
bigrams_freq <- read.table("data/bigrams_frequency.txt", header=FALSE, sep=" ")


# ###################################################################
# Motions costs/penalties
# ###################################################################

# cost of using different hands for bigram
bigram.costs.differentHand <- 2

# The cost of using the same finger to type
bigram.costs.sameFingerNoSwipeCost <- 4

# Swiping motion costs. (check swipe detection functions below)
bigram.costs.sideSwipe <- 2
bigram.costs.downSwipe <- 2

bigram.costs.perRowDifWhenUsingDiffentFingers <- 1
bigram.costs.innerRoll <- 1
bigram.costs.outerRoll <- 3

#A penalty for using pinky and ring finger for a bigram.
# pinky x ring combo penalty depends on the row diff;
# first position equals 0 row difference and last equal 2
bigram.costs.pinky_with_ring_penalty <- array (c (1,1,3), dim= 3)


# ###################################################################
# Auxiliary functions
# ###################################################################

# Auxiliar methods
isLeftHand <- function (key_pos) key_pos<=5 || (key_pos>10 && key_pos<=15 ) || (key_pos>20 && key_pos<=25 )
isHomeRow <- function (key_pos) key_pos>10 && key_pos < 21
isSameKey <- function(key1_pos, key2_pos) key1_pos == key2_pos
isSameFinger <- function(key1_pos, key2_pos) finger_map[key1_pos] == finger_map[key2_pos]

# Negative sign indicates downward movement
getKeyPosRow <-function(key_pos) (key_pos-1)%/%10
getRowDifference <- function(key1_pos, key2_pos) (key1_pos-1)%/%10 - (key2_pos-1)%/%10
isDownwardMovement <- function(rowDif) rowDif<0
isUpwardMovement <- function(rowDif) rowDif>0

isInnerRoll <- function(key1_pos, key2_pos,leftHand) {
  #Supposes that both use the same hand and does not check for that!
  return(key1_pos < key2_pos && leftHand
           || key1_pos > key2_pos && !leftHand)
}

# Check for using little and ring finger usage.
bigram.costs.usesLittleAndRing <- function (key1_pos, key2_pos)
  return(
    (finger_map[key1_pos]==1 && finger_map[key2_pos]==2)
    ||(finger_map[key1_pos]==2 && finger_map[key2_pos]==1)
    ||(finger_map[key1_pos]==7 && finger_map[key2_pos]==8)
    ||(finger_map[key1_pos]==8 && finger_map[key2_pos]==7)
  )

isPossibleToIndexFingerSideSwipe <- function (key1_pos, key2_pos, isLeftHand, rowDifference){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    (finger_map[key1_pos]==4 || finger_map[key1_pos]==5) # uses index
     && isHomeRow(key2_pos) # only consider swipes that go into the homerow
      && !isUpwardMovement(rowDifference) # check if the movement is not from a lower row, downward diagonal is accepted
      && # check that keys are adjacent and the movement is inward
        (key1_pos+1==key2_pos && isLeftHand
      || key1_pos==1+key2_pos && !isLeftHand)
    )
}

# I am not sure if this is doable...
# there might be someone who does it just like I do it with the index finger.
# I don't check the diagonal as a possible movement.
isPossibleToRingFingerSideSwipe <- function (key1_pos, key2_pos, isLeftHand){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    (finger_map[key1_pos]==2 || finger_map[key1_pos]==7) # uses ring finger
     && isHomeRow(key2_pos) # only consider swipes that go into the homerow
      && isHomeRow(key1_pos) # do not accept diagonal movements
      && # check that keys are adjacent and the movement is inward
        (key1_pos-1==key2_pos && isLeftHand
      || key1_pos==-+key2_pos && !isLeftHand)
    )
}

isPossibleToVerticalSwipe <-  function (key1_pos, key2_pos,rowDifference){
  #Supposes the same finger is used for both keys and does not check for that!
  return(
    rowDifference == -1 #moves only one key down
    && finger_map[key1_pos] != 1 && finger_map[key1_pos] != 8 #exclude little finger swipes
    && (key1_pos-1) %% 10 == (key2_pos-1) %% 10     # check if collumn is the same
  )
}

# ###################################################################
# Motion Cost Function
# ###################################################################

bigram.bigram_cost <- function(key1_pos, key2_pos){
  key1_OnLeftHand <- isLeftHand(key1_pos)
  rowDiff <- getRowDifference(key1_pos,key2_pos)

  if(isSameFinger(key1_pos, key2_pos)){
    #Same finger used to type bigram

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
    return(bigram.costs.sameFingerNoSwipeCost)
  }

  # Different fingers used

  if(key1_OnLeftHand != isLeftHand(key2_pos))
    return(bigram.costs.differentHand) #uses different hands

  abs_rowDiff <- abs(rowDiff)
  cost <- abs_rowDiff * bigram.costs.perRowDifWhenUsingDiffentFingers

  # Uses same hand
  if(isInnerRoll(key1_pos, key2_pos,key1_OnLeftHand)){
    #inner roll
    cost <- cost + bigram.costs.innerRoll
  }
  else cost <- cost + bigram.costs.outerRoll # outer roll

  if(bigram.costs.usesLittleAndRing(key1_pos,key2_pos))
    cost <- cost + bigram.costs.pinky_with_ring_penalty[abs_rowDiff+1]

  return(cost);
}

# ###################################################################
# Cost/Effort function used to calculate fitness
# ###################################################################

#pre compute all possible values
bigram.pre_computed_costs <- matrix(0,nrow = 30, ncol = 30)
  for(fp in 1:30)#1st letter position
  for(sp in 1:30)#2nd letter position
    bigram.pre_computed_costs[fp,sp] <- bigram.bigram_cost(fp, sp)

auxL <- matrix(c(1:26))
t_bigrams_freq <- t(bigrams_freq)
auxFUN <- function(s, f, layout) (bigram.pre_computed_costs[layout[f],layout[s]] * t_bigrams_freq[f,s])[1]
bigram.cost <- function (layout)
{
  cost <- 0
  for(first_letter in 1:26)
    cost <- cost + sum(apply(auxL, 1, auxFUN,first_letter,layout))

  return(cost)
}

# ###################################################################
# Wrap things up to be used in Fitness.R
# ###################################################################

effort.bigrams <- c(
    cost= bigram.cost,
    max=max(bigram.pre_computed_costs)*100,
    min=min(bigram.pre_computed_costs)*100
)

# educated guess based on tests. will make the best closer to 1.
effort.bigrams$max <- effort.bigrams$max - (effort.bigrams$max - effort.bigrams$min)*(1-0.8183)
effort.bigrams$min <- effort.bigrams$min + (effort.bigrams$max - effort.bigrams$min)*(1-0.8183)