# Title     : Fitness
# Objective : Define final fitness to be used in GA.R and Evaluate.R
# Created by: Bruno
# Created on: 09/07/2021

source("fitness/AuxFunctions.R")
source("fitness/V1/KeyFrequencyF.R")
#source("fitness/BigramMovementsFrequencyF.R")
source("fitness/V1/top2gramsF.R")
source("fitness/V1/top3gramsF.R")
source("fitness/V1/top4gramsF.R")
source("fitness/V1/top5gramsF.R")
source("fitness/constraints/VowelConstraintF.R")
source("fitness/constraints/SymbolConstraintF.R")

# ----------------------------------------------------------------
# Effort weight distribution functions

set_uniform_weights <- function(efforts) for(i in seq_along(efforts)) efforts[[i]]$weight <<- 1/length(efforts)

#' Weights increase by powers of the given base, from last (smallest weight) to first (biggest weight).
#'
#' Example for base 2 and 3 efforts list:
#'  sum of all weights = 2^3-1 = 7
#'  3rd effort weight = 2^0 / 7 = 1/7
#'  2nd effort weight = 2^1 / 7 = 2/7
#'  1st effort weight = 2^2 / 7 = 4/7
#' @param base The base value to be raised. Should be an integer higher than 1.
set_powers<- function(efforts, base){
  sum <- (1+base)+base*(base^(length(efforts)-1)-base)/(base-1)
  for(i in seq_along(efforts))
    efforts[[i]]$weight <<- base^(length(efforts)-i) / sum
}

#' Weights increase by raising increasing natural numbers by the given power, from last (smallest weight) to first (biggest weight).
#'
#' Example for power 2 and 3 efforts list:
#'  sum of all weights = 1+4+9 = 14
#'  3rd effort weight = 1^1 / 14 = 1/14
#'  2nd effort weight = 2^2 / 14 = 4/14
#'  1st effort weight = 3^3 / 14 = 9/14
#' @param power The power used to raise the increasing bases. Should be an integer higher than 1.
set_exponential_weights <- function(efforts, power){
  #note that optimization using fauldaber is not relevant as the list still needs to be iterated...
  #faulhaber <- function(n, p) n^(p+1)/(p+1) + n^p/2 + sum(i in 2..p : bernouli(i)/i! * dfac(p, i-1) * n^(p-k+1) )
  sum <- 0
  for(i in seq_along(efforts)){
    efforts[[i]]$weight <- ( length(efforts) - i + 1)^power
    sum <- sum + efforts[[i]]$weight
  }
  for(i in seq_along(efforts))
    efforts[[i]]$weight <<- efforts[[i]]$weight / sum
}

# ----------------------------------------------------------------
# Set effort heuristics max and minimum values
# warning: do not change this unless you know what you are doing
#TODO: these values may no longer be valid for the latest updated bigram costs matrix
leeway<-0.01
effort.top_bigrams$min  <-2.03950836913362 * (1 - leeway)
effort.top_bigrams$max  <-4.03114126178524 * (1 + leeway)
effort.top_trigrams$min <-4.12510678269589 * (1 - leeway)
effort.top_trigrams$max <-8.01782469843075 * (1 + leeway)
effort.top_fourgrams$min<-6.24853169244983 * (1 - leeway)
effort.top_fourgrams$max<-12.0811080144134 * (1 + leeway)
effort.top_fivegrams$min<-8.32047577222674 * (1 - leeway)
effort.top_fivegrams$max<-16.1397376951138 * (1 + leeway)

# ----------------------------------------------------------------
# Initialize lists and related methods
efforts <- list()
constraints <- list()

add_effort <- function(effort) efforts[[length(efforts)+1]] <<- effort
add_contraint <- function(constraint) constraints[[length(constraints)+1]] <<- constraint

# ----------------------------------------------------------------
# Add contraints
add_contraint(contraint.vowels)
add_contraint(contraint.symbol)

# ----------------------------------------------------------------
# Add efforts
add_effort(effort.keys)
add_effort(effort.top_bigrams)
add_effort(effort.top_trigrams)
add_effort(effort.top_fourgrams)
add_effort(effort.top_fivegrams)

# ----------------------------------------------------------------
# Set efforts weights
set_uniform_weights(efforts)
#set_powers(efforts, 2)
#set_exponential_weights(efforts, 2)

# ----------------------------------------------------------------
# Pre Compute stuff
MaxPossibleEffort <- effort.computeMaxPossibleEffort(efforts)

# ----------------------------------------------------------------
# Fitness related functions

effortScore <- function(ind) MaxPossibleEffort - effort.computeTotalEffort(efforts_list = efforts, individual = ind)


#' Computes the penalty of each contraint in contraints for an individual.
#' @param ind individual (genetic representation).
#' @return The sum of all computed the penalties.
scorePenalty <- function(ind) penalty.computeTotalPenalty(constraints_list = constraints, individual = ind)


#' Computes the fitness score of an individual.
#' @param ind individual (genetic representation).
#' @return Fitness of the given individual.
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