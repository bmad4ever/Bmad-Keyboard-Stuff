# Title     : Key/Character Frequency Fitness
# Objective : Estimate the effort of a layout with respect to
#              the frequency of the characters and their key assignment,
#              not accounting for words or n-gram related motions
# Created by: Bruno
# Created on: 21/06/2021

# Finger effort
keys.weights <-  read.table("data/singles_weight.txt", header=FALSE, sep=" ")
keys.weights <- as.vector(t(keys.weights))
keys.freq <- read.table("data/letter_frequency.txt", header=FALSE, sep=" ")

keys.n <- length(keys.weights)
effort.keys <- c(
    cost=function(layout) sum(keys.freq[1:keys.n , 2]*keys.weights[layout[1:keys.n]]),
    max=sum(sort(keys.weights)*sort(keys.freq[1:keys.n , 2])),
    min=sum(sort(keys.weights, decreasing=TRUE)*sort(keys.freq[1:keys.n , 2]))
  )
