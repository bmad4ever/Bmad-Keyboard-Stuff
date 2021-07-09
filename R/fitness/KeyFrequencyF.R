# Title     : Key/Character Frequency Fitness
# Objective : Estimate the effort of a layout with respect to
#              the frequency of the characters and their key assignment,
#              not accounting for words or n-gram related motions
# Created by: Bruno
# Created on: 21/06/2021

# Finger effort
weights <-  read.table("data/singles_weight.txt", header=FALSE, sep=" ")
weights <- as.vector(t(weights))
key_freq <- read.table("data/letter_frequency.txt", header=FALSE, sep=" ")

n <- length(weights)
effort.keys <- c(
    cost=function(layout) sum(key_freq[1:n, 2]*weights[layout[1:n]]),
    max=sum(sort(weights)*sort(key_freq[1:n, 2])),
    min=sum(sort(weights, decreasing=TRUE)*sort(key_freq[1:n, 2]))
  )
