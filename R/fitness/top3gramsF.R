# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 11/07/2021


source("fitness/BigramMovementsFrequencyF.R")


n_tri <- 8653%/%4 # the number of top entries to filter and use
trigrams_freq <- read.table("data/ranked3grams.txt", header=FALSE, sep="\t")
trigrams_freq <- trigrams_freq[1:n_tri,1:2]
trigrams_freq[1:n_tri,2] <- trigrams_freq[1:n_tri,2] /sum(trigrams_freq[1:n_tri,2])

letter2number <- function(x) utf8ToInt(x) - utf8ToInt("A") + 1L
trigram2indexes <- function(x) unname(sapply(as.vector(x), letter2number))

trigrams_indexes <- sapply(trigrams_freq[1:n_tri,1], trigram2indexes)
trigrams_freq <- trigrams_freq[1:n_tri,2]

evaluateTri <- function(i, layout)
  ( bigram.pre_computed_costs[layout[trigrams_indexes[1,i]],layout[trigrams_indexes[2,i]]] +
    bigram.pre_computed_costs[layout[trigrams_indexes[2,i]],layout[trigrams_indexes[3,i]]] ) * trigrams_freq[i]


trigrams.cost <- function(layout)
{
  cost <- 0
  for (i in 1:n_tri)
   cost <- cost + evaluateTri(i,layout)
  return(cost)
}


effort.top_trigrams <- c(
    cost=trigrams.cost,
    tmax=sum(trigrams_freq)*max(bigram.pre_computed_costs)*2,
    tmin=sum(trigrams_freq)*min(bigram.pre_computed_costs)*2
  )


testIt <- function(){
  characters <- c( letters[1:26] , "." , "," , ";" , "-" )
  layout <- read.table("layouts/qwerty.txt", header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))
  individual <- match(characters,flat_layout)
  print(effort.top_trigrams$cost(individual))
}
