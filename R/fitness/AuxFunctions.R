# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 25/06/2021

# Compute Effort ---------------------------------------------------

effort.compute <- function (x, ind) x$cost(ind)
effort.normalize <- function(x, cost) {
  #if(is.null(x$max))
  #  stop("Tried to normalize without defining an upper bound.")

  #if(is.null(x$min)) {
  #  warning("No lower bound was defined. Will use 0 as lower bound.")
  #  return(cost / x$max)
  #}
  #else
  return( (cost-x$min) /
            (x$max-x$min) )
}
effort.weight <- function(x, cost) {
  #if(is.null(x$weight)){
  #  warning("Weight was not defined. Will use weight=1.")
  #  return(cost)
  #}
  return( cost * x$weight)
}

#note: these funcs are also implemented in misc/ProfilePerformance using pipes.
#      altough less efficient, they are easier to read than the following ones.
effort.computeTotalEffort <- function (efforts_list,individual) sum(unlist(lapply(seq_along(efforts_list), function(x) effort.weight(efforts_list[[x]], effort.normalize(efforts_list[[x]], effort.compute(efforts_list[[x]], individual))) )))
effort.computeMaxPossibleEffort <- function (efforts_list) sum(unlist(lapply(seq_along(efforts_list), function(x) efforts_list[[x]]$weight )))

penalty.compute <- function(x, ind) (1-as.double(x$constraint(ind)))*x$penalty
penalty.computeTotalPenalty <- function (constraints_list,individual) sum(unlist(lapply(constraints_list, function (x) penalty.compute(x,individual) )))
