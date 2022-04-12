# Title     : Fitness
# Objective : Define final fitness to be used in GA.R and Evaluate.R
# Created by: Bruno
# Created on: 09/07/2021

source("fitness/AuxFunctions.R")
source("fitness/KeyFrequencyF.R")
source("fitness/BigramMovementsFrequencyF.R")
source("fitness/top2gramsF.R")
source("fitness/top3gramsF.R")
source("fitness/top4gramsF.R")
source("fitness/top5gramsF.R")
source("fitness/VowelConstraintF.R")
source("fitness/SymbolConstraintF.R")


# set effort heuristics max and minimum values
leeway<-0.01
effort.top_bigrams$min  <-2.03950836913362 * (1 - leeway)
effort.top_bigrams$max  <-4.03114126178524 * (1 + leeway)
effort.top_trigrams$min <-4.12510678269589 * (1 - leeway)
effort.top_trigrams$max <-8.01782469843075 * (1 + leeway)
effort.top_fourgrams$min<-6.24853169244983 * (1 - leeway)
effort.top_fourgrams$max<-12.0811080144134 * (1 + leeway)
effort.top_fivegrams$min<-8.32047577222674 * (1 - leeway)
effort.top_fivegrams$max<-16.1397376951138 * (1 + leeway)



# define effort and weight different effort measurements
efforts <- list()

effort.keys$weight <- 10/30
efforts[[length(efforts)+1]] <- effort.keys

effort.top_bigrams$weight <- 6/30
efforts[[length(efforts)+1]] <- effort.top_bigrams

effort.top_trigrams$weight <- 3/30
efforts[[length(efforts)+1]] <- effort.top_trigrams

effort.top_fourgrams$weight <- 10/30
efforts[[length(efforts)+1]] <- effort.top_fourgrams

effort.top_fivegrams$weight <- 1/30
efforts[[length(efforts)+1]] <- effort.top_fivegrams

MaxPossibleEffort <- effort.computeMaxPossibleEffort(efforts)

effortScore <- function(ind) MaxPossibleEffort - effort.computeTotalEffort(efforts_list = efforts, individual = ind)

# define constraints and their penalty
constraints <- list()

constraints[[length(constraints)+1]] <- contraint.vowels
constraints[[length(constraints)+1]] <- contraint.symbol

scorePenalty <- function(ind) penalty.computeTotalPenalty(constraints_list = constraints, individual = ind)


fitness <- function(ind)
{
  return(
    max(0.0001, effortScore(ind) - scorePenalty(ind) )
  )
}


individual_effort_component_scores <- function(ind){
  fitness <- vector()

  for (i in seq_along(efforts))
  {
      component <- efforts[[i]]
      fitness[[i]] <-  (1 - effort.normalize(component,effort.compute(component,ind))) * efforts[[i]]$weight
  }

  #offset <- length(fitness)
  #for (i in seq_along(constraints))
  #{
  #    component <- constraints[[i]]
  #    fitness[[i+offset]] <- penalty.compute(component,ind)
  #}

  return(fitness)
}