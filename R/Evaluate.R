# Title     : Evaluate
# Objective : Evaluate and compare existing layouts
# Created by: Bruno
# Created on: 09/07/2021

source("Fitness.R")


# auxiliar data
characters <- c( letters[1:26] , "." , "," , ";" , "-" )
fitnesses <- vector()
files <- list.files(path="layouts", pattern="*.txt", full.names=TRUE, recursive=FALSE)
layouts <- rep(list(matrix(NA, c(3, 10))), length(files))


# read files and store layouts' fitness
for(i in seq_along(files)) {
  #print(files[i])

  # read layout
  layout <- read.table(files[i], header=FALSE, sep=" ")
  flat_layout <- as.vector(as.matrix(t(layout)))

  # generate an individual from the phenotype (layout) so that it can be evaluated
  individual <- match(characters,flat_layout)
    fit <- fitness(individual)

  layouts[[i]] <- layout
  fitnesses[length(fitnesses)+1] <- fit
}


# get indexes ordered from least to most fit
fitnesses_ordered_indexes <- sort(fitnesses, index.return=TRUE)$ix

# print layouts, ordered by fitness
for(i in fitnesses_ordered_indexes){
  cat("\nLayout: ")
  cat(files[i])
  cat("\nFitness: ")
  cat( fitnesses[i] )
  cat("\n")
  print(layouts[i])
}

# plot fitness
files <- stringr::str_remove(files,".txt")
files <- stringr::str_remove(files,"layouts/")
par(las=2) # make label text perpendicular to axis
par(mar=c(5,6,4,2)) # increase y-axis margin.
barplot(main="Layouts Fitness",
        height=fitnesses, names=files,
        col="#cccccc", horiz=T , xpd=FALSE, #las=1, xpd=FALSE,mar=c(5,8,4,2),
        xlim=c(min(fitnesses)-0.03,max(fitnesses))+0.02
)