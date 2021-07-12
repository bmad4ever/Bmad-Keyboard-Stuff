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
fitc <- matrix(NA,nrow = length(files), ncol = length(efforts))


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

  fitc[i,] <- fitness_components(individual)
}
print(fitc)

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
par(mfrow=c(1,2))

files <- stringr::str_remove(files,".txt")
files <- stringr::str_remove(files,"layouts/")
par(las=2) # make label text perpendicular to axis
par(mar=c(5,7,4,2)) # increase y-axis margin.
barplot(main="Layouts Fitness",
        height=fitnesses, names=files,
        col=c("#bbbbbb"), horiz=T , xpd=FALSE,
        xlim=c(min(fitnesses)-0.03,max(fitnesses)+0.02)
)

par(mar=c(5,4,4,2))
barplot(t(fitc), main="Fitness Components",
  col=c("#aaaaaa","#888888","#666666"),
  beside=TRUE, horiz=T,
  #xlim=c(min(fitc)-0.03,max(fitc)+0.02), xpd=FALSE
)