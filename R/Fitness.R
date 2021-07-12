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


effort.keys$weight <- 200 /1000
efforts[[length(efforts)+1]] <- effort.keys

effort.bigrams$weight <- 100/1000
efforts[[length(efforts)+1]] <- effort.bigrams

effort.trigrams$weight <- 800/1000
efforts[[length(efforts)+1]] <- effort.trigrams

MaxPossibleEffort <- effort.computeMaxPossibleEffort(efforts)

fitness <- function(ind)
{
  return( MaxPossibleEffort - effort.computeTotalEffort(efforts_list = efforts,individual = ind) )
}