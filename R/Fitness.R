# Title     : Fitness
# Objective : Define final fitness to be used in GA.R and Evaluate.R
# Created by: Bruno
# Created on: 09/07/2021

source("fitness/AuxFunctions.R")
source("fitness/KeyFrequencyF.R")
source("fitness/BigramMovementsFrequencyF.R")
source("fitness/3gramF.R")

# define effort and weight different effort measurements
efforts <- list()


effort.keys$weight <- 10/30
efforts[[length(efforts)+1]] <- effort.keys

effort.bigrams$weight <- 10/30
efforts[[length(efforts)+1]] <- effort.bigrams

effort.trigrams$weight <- 10/30
efforts[[length(efforts)+1]] <- effort.trigrams

MaxPossibleEffort <- effort.computeMaxPossibleEffort(efforts)

fitness <- function(ind)
{
  return( MaxPossibleEffort - effort.computeTotalEffort(efforts_list = efforts,individual = ind) )
}


fitness_components <- function(ind){
  fitness <- vector()
  for (i in seq_along(efforts))
  {
      component <- efforts[[i]]
      fitness[[i]] <- (1 - effort.normalize(component,effort.compute(component,ind))) * efforts[[i]]$weight
  }
  return(fitness)
}