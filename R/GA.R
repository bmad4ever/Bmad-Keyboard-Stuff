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

selection <- function(x) gabin_tourSelection(x, k=2)
crossover <- function(x,p) gaperm_pmxCrossover(x,p)
mutation <- function(x,p) gaperm_swMutation(x,p)
result <- ga(type="permutation",
             fitness=fitness,
             lower=lw, upper=up,
             selection = selection,
             elitism = 100,
             pcrossover =  0.3 , pmutation  =  .9 ,
             crossover = crossover,
             mutation = mutation,
             monitor=TRUE,
             popSize = 10000,
             maxiter = 240,
             parallel = parallel::detectCores()
)
summary(result)
par(mfrow=c(1,1))
plot(result)


# print best layout(s)
characters <- c( letters[1:26] , "." , "," , ";" , "-" ) # characters to be mapped
cat('\nbest layout(s):\n')
for (i in 1:(length(result@solution)/30)){
  print(matrix(characters[match(1:n, result@solution[i,])], nrow = 3, ncol = 10,byrow=TRUE))
  cat('\n')
}