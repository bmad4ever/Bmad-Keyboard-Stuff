# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 11/07/2021


source("R/fitness/efforts/2GramEffortMatrix.R")


n_four <- 42171%/%8 # the number of top entries to filter and use
fourgrams_freq <- read.table("data/ranked4grams.txt", header=FALSE, sep="\t")
fourgrams_freq <- fourgrams_freq[1:n_four,1:2]
fourgrams_freq[1:n_four,2] <- fourgrams_freq[1:n_four,2] /sum(fourgrams_freq[1:n_four,2])

letter2number <- function(x) utf8ToInt(x) - utf8ToInt("A") + 1L
fourgram2indexes <- function(x) unname(sapply(as.vector(x), letter2number))

fourgrams_indexes <- sapply(fourgrams_freq[1:n_four,1], fourgram2indexes)
fourgrams_freq <- fourgrams_freq[1:n_four,2]

evaluateFour <- function(i, layout)
  ( bigram.pre_computed_costs[layout[fourgrams_indexes[1,i]],layout[fourgrams_indexes[2,i]]] +
    bigram.pre_computed_costs[layout[fourgrams_indexes[2,i]],layout[fourgrams_indexes[3,i]]] +
    bigram.pre_computed_costs[layout[fourgrams_indexes[3,i]],layout[fourgrams_indexes[4,i]]]
  ) * fourgrams_freq[i]


fourgrams.cost <- function(layout)
{
  cost <- 0
  for (i in 1:n_four)
   cost <- cost + evaluateFour(i,layout)
  return(cost)
}


effort.top_fourgrams <- c(
    cost=fourgrams.cost,
    tmax=sum(fourgrams_freq)*max(bigram.pre_computed_costs)*3,
    tmin=sum(fourgrams_freq)*min(bigram.pre_computed_costs)*3
  )


testIt <- function(){
  characters <- c(letters[1:26] , "..", "," , ";" , "-" )
  layout <- read.table("layouts/qwerty.txt", header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))
  individual <- match(characters,flat_layout)
  print(effort.top_fourgrams$cost(individual))
}
