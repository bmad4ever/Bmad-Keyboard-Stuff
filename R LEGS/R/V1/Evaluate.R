# Title     : Evaluate
# Objective : Evaluate and compare existing layouts
# Created by: Bruno
# Created on: 09/07/2021

if(!exists("Definitions")) source("R/Definitions.R")
source("R/V1/Fitness.R")

layoutsPath <- "layouts2compare"

# auxiliar data
fitnesses <- vector()
effort_scores <- vector()
penalties <- vector()
files <- list.files(path=layoutsToComparePath, pattern="*.txt", full.names=TRUE, recursive=FALSE)
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
  fitnesses[length(fitnesses)+1] <- fitness(individual)
  effort_scores[length(effort_scores)+1] <- effortScore(individual)
  penalties[length(penalties)+1] <- scorePenalty(individual)

  fitc[i,] <- individual_effort_component_scores(individual)
}
#print(fitc)

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
par(mfrow=c(2,2))

files <- stringr::str_remove(files,".txt")
files <- stringr::str_remove(files,layoutsPath)
files <- stringr::str_remove(files,"/")
par(las=2) # make label text perpendicular to axis
par(mar=c(5,7,4,2)) # increase y-axis margin.
barplot(main="Layouts' Fitness",
        height=fitnesses, names=files,
        col= "#bbbbbb", horiz=T , xpd=FALSE,
        xlim=c(min(fitnesses)-0.03,max(fitnesses)+0.05)
)

files <- stringr::str_remove(files,".txt")
files <- stringr::str_remove(files,"layouts/")
par(las=2) # make label text perpendicular to axis
par(mar=c(5,7,4,2)) # increase y-axis margin.
barplot(main="Effort Score ",
        height=effort_scores, names=files,
        col= "#bbbbbb", horiz=T , xpd=FALSE,
        xlim=c(min(effort_scores)-0.03,max(effort_scores)+0.05)
)

files <- stringr::str_remove(files,".txt")
files <- stringr::str_remove(files,"layouts/")
par(las=2) # make label text perpendicular to axis
par(mar=c(5,7,4,2)) # increase y-axis margin.
barplot(main="Score Penalty",
        height=penalties, names=files,
        col= "#bbbbbb", horiz=T , xpd=FALSE,
        xlim=c(min(penalties)-0.03,max(penalties)+0.02)
)

par(mar=c(5,4,4,2))
barplot(t(fitc), main="Individual Effort Component Scores",
        names=files,
  col=c("#000000","#000000","#000000"),
  beside=TRUE, horiz=T,
  space=c(0,3)
  ,xlim=c(min(fitc)-0.05,max(fitc)+0.05), xpd=FALSE
)