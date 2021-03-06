# Title     : GA solution for keyboard layouts
# Objective : Find the most viable keyboard layout for the given fitness
# Created by: Bruno
# Created on: 21/06/2021

# An Individual is represented in the following way:
# - permutation of non repeated numbers
#     each number corresponds to a position in the keyboard layout
# - the indexes corresponds to a letter/symbol
#     with respect to the order presented in the list: 'keys'


source("Fitness.R")

library(GA)
# Genetic Algorithm library. Sources:
# https://anaconda.org/conda-forge/r-ga
# https://luca-scr.github.io/GA/articles/GA.html

n <- 30 # number of keys on the layout
lw <- seq(1,1, length.out=n)
up <- seq(n,n, length.out=n)
print(lw[1])
selection <- function(x) gabin_tourSelection(x, k=3)
crossover <- function(x,p) gaperm_pmxCrossover(x,p)
mutation <- function(x,p) gaperm_swMutation(x,p)
result <- ga(type="permutation",
             fitness=fitness,
             lower=lw, upper=up,
             selection = selection,
             pcrossover =  0.5 , pmutation  =  .5 ,
             crossover = crossover,
             mutation = mutation,
             monitor=TRUE,
             popSize = 400,
             maxiter = 200)
summary(result)
plot(result)


# print best layout(s)
characters <- c( letters[1:26] , "." , "," , ";" , "-" ) # characters to be mapped
cat('\nbest layout(s):\n')
for (i in 1:(length(result@solution)/30)){
  print(matrix(characters[match(1:n, result@solution[i,])], nrow = 3, ncol = 10,byrow=TRUE))
  cat('\n')
}