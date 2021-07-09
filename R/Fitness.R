# Title     : Fitness
# Objective : Define final fitness to be used in GA.R and Evaluate.R
# Created by: Bruno
# Created on: 09/07/2021

source("fitness/AuxFunctions.R")
source("fitness/KeyFrequencyF.R")
source("fitness/BigramMovementsFrequencyF.R")

# define effort and weight different effort measurements
efforts <- list()

effort.keys$weight <- 30/100
efforts[[length(efforts)+1]] <- effort.keys

effort.bigrams$weight <- (1-effort.keys$weight)
efforts[[length(efforts)+1]] <- effort.bigrams

MaxPossibleEffort <- effort.computeMaxPossibleEffort(efforts)

fitness <- function(ind)
{
  return( MaxPossibleEffort - effort.computeTotalEffort(efforts_list = efforts,individual = ind) )
}