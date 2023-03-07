# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 20/04/2022

library(hash)
source("R/fitness/QueriesAndDefinitions.R")

# ###################################################################
# Motions costs/penalties
# ###################################################################

fivegram.costs.no_hand_alternation_penalty <- 3

# ###################################################################
# Fivegram Motion Cost Functions
# ###################################################################

fivegram.fivegram_cost <- function(key1, key2, key3, key4, key5) {
  sum <- 0

  # TODO consider potential swipes

  fingers <- finger_map[c(key1, key2, key3, key4, key5)]

  if(all(fingers < 5) || all(fingers >= 5))
    sum <- sum + fivegram.costs.no_hand_alternation_penalty

  return(sum)
}

fivegram.fivegram_cost(1,2,3,4,5)

# ###################################################################
# Pre compute all possible values  *cheat using a list of index that have a value*
# ###################################################################

# Create a new hashset object and add the key-value pairs
fivegram.hashmap <- hash()

# Create a vector of key-value pairs
for(i1 in 1:30)
for(i2 in 1:30)
for(i3 in 1:30)
for(i4 in 1:30)
for(i5 in 1:30){
  computed_effort <- fivegram.fivegram_cost(i1,i2,i3,i4,i5)
  if(computed_effort > 0){
      keys_vector <- c(i1, i2, i3, i4, i5)
      fivegram.hashmap[[paste(keys_vector, collapse = "")]] <- computed_effort
    }
}

fivegram.pre_computed_costs <- function(key1, key2, key3, key4, key5){
  stored_effort <- fivegram.hashmap[[paste(c(key1, key2, key3, key4, key5), collapse = "")]]
  if(stored_effort == NULL)
    return(0)
  return(stored_effort)
}



testIt <- function(){
  print(
    paste(c(11, 12, 13, 14, 15), collapse = "")
    %in% keys(fivegram.hashmap)
  )

    print(
    paste(c(19, 20, 18, 16, 17), collapse = "")
    %in% keys(fivegram.hashmap)
  )

    print(
    paste(c(19, 12, 13, 14, 15), collapse = "")
    %in% keys(fivegram.hashmap)
  )

   print(fivegram.hashmap[[paste(c(11, 12, 13, 14, 15), collapse = "")]])
   print(fivegram.hashmap[[paste(c(19, 20, 18, 16, 17), collapse = "")]])
   print(fivegram.hashmap[[paste(c(19, 12, 13, 14, 15), collapse = "")]])

  print(fivegram.pre_computed_costs(11, 12, 13, 14, 15))
  print(fivegram.pre_computed_costs(19, 12, 13, 14, 15))
}
