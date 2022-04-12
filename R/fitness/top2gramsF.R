# Title     : Bigram/Motion Frequency Fitness
# Objective : Estimate the effort of a layout with respect to
#               bigram frequency and respective input motion effort
# Created by: Bruno
# Created on: 27/06/2021


source("fitness/BigramMovementsFrequencyF.R")

# note: the difference is negligible when compared to the complete bigram analysis
n_bi <- 669%/%2  # the number of top entries to filter and use
top_bigrams_freq <- read.table("data/top2grams.txt", header=FALSE, sep=" ")
top_bigrams_freq <- top_bigrams_freq[1:n_bi,1:2]
top_bigrams_freq[1:n_bi,2] <- top_bigrams_freq[1:n_bi,2] /sum(top_bigrams_freq[1:n_bi,2])

# note: can't use vector for indexes because NA is special in R
letter2number <- function(x) utf8ToInt(x) - utf8ToInt("A") + 1L
bigram2indexes <- function(x) unname(lapply(strsplit(toString(x),'')[[1]], letter2number))

bigrams_indexes <- matrix(unlist(lapply(top_bigrams_freq[1:n_bi,1], bigram2indexes)), ncol = n_bi, nrow=2, byrow = FALSE)
top_bigrams_freq <- top_bigrams_freq[1:n_bi,2]

evaluateBi <- function(i, layout)
  bigram.pre_computed_costs[layout[bigrams_indexes[1,i]],layout[bigrams_indexes[2,i]]] * top_bigrams_freq[i]


bigramsV2.cost <- function(layout)
{
  cost <- 0
  for (i in 1:n_bi)
   cost <- cost + evaluateBi(i,layout)
  return(cost)
}


effort.top_bigrams <- c(
    cost=bigramsV2.cost,
    tmax=sum(top_bigrams_freq)*max(bigram.pre_computed_costs),
    tmin=sum(top_bigrams_freq)*min(bigram.pre_computed_costs)
  )

testIt <- function(){
  characters <- c( letters[1:26] , "." , "," , ";" , "-" )
  layout <- read.table("layouts/qwerty.txt", header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))
  individual <- match(characters,flat_layout)
  print(effort.top_bigrams$cost(individual))
}
