# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 11/07/2021


source("fitness/BigramMovementsFrequencyF.R")

# filter the n top entries.
n_tri <- 300
trigrams_freq <- read.table("data/ranked3grams.txt", header=FALSE, sep="\t")
trigrams_freq <- trigrams_freq[1:n_tri,1:2]
trigrams_freq[1:n_tri,2] <- trigrams_freq[1:n_tri,2] * 1/sum(trigrams_freq[1:n_tri,2])

letter2number <- function(x) {utf8ToInt(x) - utf8ToInt("A") + 1L}
trigram2indexes <- function(x) as.vector(unname(sapply(as.vector(x), letter2number)))

trigrams_indexes <- sapply(trigrams_freq[1:n_tri,1], trigram2indexes)
trigrams_freq <- trigrams_freq[1:n_tri,2]

# test it
characters <- c( letters[1:26] , "." , "," , ";" , "-" )
  layout <- read.table("layouts/qwerty.txt", header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))
  individual <- match(characters,flat_layout)


evaluateTri <- function(i, layout)
  ( bigram.pre_computed_costs[layout[trigrams_indexes[1,i]],layout[trigrams_indexes[2,i]]] +
    bigram.pre_computed_costs[layout[trigrams_indexes[2,i]],layout[trigrams_indexes[3,i]]] ) * trigrams_freq[i]


trigams.cost <- function(layout)
{
  cost <- 0
  for (i in 1:n_tri)
   cost <- cost + evaluateTri(i,layout)
  return(cost)
}


effort.trigrams <- c(
    cost=trigams.cost,
    max=sum(trigrams_freq)*max(bigram.pre_computed_costs)*2,
    min=sum(trigrams_freq)*min(bigram.pre_computed_costs)*2
  )


# educated guess based on tests. will make the best closer to 1.
effort.trigrams$max <- effort.trigrams$max - (effort.trigrams$max - effort.trigrams$min)*(0.1533)
effort.trigrams$min <- effort.trigrams$min + (effort.trigrams$max - effort.trigrams$min)*(0.1533)