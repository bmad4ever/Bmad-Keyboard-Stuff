# Title     : TODO
# Objective : Estimate maximum possible fitness values for each fitness component
# Created by: Bruno
# Created on: 11/04/2022

# Note that:
#  Key Frequency max effort can be known and does not require a genetic algorithm pass to compute
#  Contrains, which check if a specific conditioon is true or falso also don't require computation

library(GA)

ga_estimate_best <- function(fitness){

  n <- 30 # number of keys on the layout
  lw <- seq(1,1, length.out=n)
  up <- seq(n,n, length.out=n)

  selection <- function(x) gabin_tourSelection(x, k=2)
  crossover <- function(x,p) gaperm_pmxCrossover(x,p)
  mutation <- function(x,p) gaperm_swMutation(x,p)
  result <- ga(type="permutation",
             fitness=fitness,
             lower=lw, upper=up,
             selection = selection,
             elitism = 50,
             pcrossover =  0.3 , pmutation  =  .9 ,
             crossover = crossover,
             mutation = mutation,
             monitor=TRUE,
             popSize = 10000,
             maxiter = 200,
             parallel = parallel::detectCores()
  )
  plot(result)
  return(result@fitnessValue)
}



source("Fitness.R")



FindMinMax <- function(effort)
{
  max_effort <- function(ind) effort$cost(ind)
  min_effort <- function(ind) effort$tmax - effort$cost(ind)

  estimated_max_cost <- ga_estimate_best(max_effort)
  estimated_min_cost <- effort$tmax - ga_estimate_best(min_effort)

  return( c(min=estimated_min_cost,max=estimated_max_cost) )

  # then, elsewhere, to add some leeway:
  #    effort$min<-effort$rmin * (1-leeway_margin)
  #    effort$max<-effort$rmax * (1+leeway_margin)
}


limits <- list()
efforts <- list()
#efforts[[length(efforts)+1]] <- effort.keys
efforts[[length(efforts)+1]] <- effort.top_bigrams
efforts[[length(efforts)]]$name <- deparse(substitute(effort.top_bigrams))
efforts[[length(efforts)+1]] <- effort.top_trigrams
efforts[[length(efforts)]]$name <- deparse(substitute(effort.top_trigrams))
efforts[[length(efforts)+1]] <- effort.top_fourgrams
efforts[[length(efforts)]]$name <- deparse(substitute(effort.top_fourgrams))
efforts[[length(efforts)+1]] <- effort.top_fivegrams
efforts[[length(efforts)]]$name <- deparse(substitute(effort.top_fivegrams))

par(mfrow=c(length(efforts),2))

printLimits<-function (ef) cat(paste0(ef$name, "$min<-", ef$limits["min"], "\n", ef$name, "$max<-", ef$limits["max"], "\n"))

for(i in seq_along(efforts)){
  efforts[[i]]$limits<-FindMinMax(efforts[[i]])
  printLimits(efforts[[i]])
}

cat("\n\n\n All app. limits have been computed \n\n")
#print all results at the end
for(i in seq_along(efforts))
  printLimits(efforts[[i]])
