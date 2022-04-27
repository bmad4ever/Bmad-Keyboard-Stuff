# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 11/07/2021


source("fitness/efforts/2GramEffortMatrix.R")


n_five <- 93713%/%16 # the number of top entries to filter and use
fivegrams_freq <- read.table("data/ranked5grams.txt", header=FALSE, sep="\t")
fivegrams_freq <- fivegrams_freq[1:n_five,1:2]
fivegrams_freq[1:n_five,2] <- fivegrams_freq[1:n_five,2] /sum(fivegrams_freq[1:n_five,2])

letter2number <- function(x) utf8ToInt(x) - utf8ToInt("A") + 1L
fivegram2indexes <- function(x) unname(sapply(as.vector(x), letter2number))

fivegrams_indexes <- sapply(fivegrams_freq[1:n_five,1], fivegram2indexes)
fivegrams_freq <- fivegrams_freq[1:n_five,2]

evaluateFive <- function(i, layout)
  ( bigram.pre_computed_costs[layout[fivegrams_indexes[1,i]],layout[fivegrams_indexes[2,i]]] +
    bigram.pre_computed_costs[layout[fivegrams_indexes[2,i]],layout[fivegrams_indexes[3,i]]] +
    bigram.pre_computed_costs[layout[fivegrams_indexes[3,i]],layout[fivegrams_indexes[4,i]]] +
    bigram.pre_computed_costs[layout[fivegrams_indexes[4,i]],layout[fivegrams_indexes[5,i]]]
  ) * fivegrams_freq[i]


fivegrams.cost <- function(layout)
{
  cost <- 0
  for (i in 1:n_five)
   cost <- cost + evaluateFive(i,layout)
  return(cost)
}


effort.top_fivegrams <- c(
    cost=fivegrams.cost,
    tmax=sum(fivegrams_freq)*max(bigram.pre_computed_costs)*4,
    tmin=sum(fivegrams_freq)*min(bigram.pre_computed_costs)*4
  )


testIt <- function(){
  characters <- c(letters[1:26] , "..", "," , ";" , "-" )
  layout <- read.table("../../layouts/qwerty.txt", header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))
  individual <- match(characters,flat_layout)
  print(effort.top_fivegrams$cost(individual))
}
