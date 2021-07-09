# Title     : Profile different code styles
# Objective : Check time performance cost of using pipes and other misc. functions
# Created by: Bruno
# Created on: 25/06/2021

source("fitnesses/AuxFunctions.R")
source("fitnesses/BigramMovementsFrequencyF.R")

library('proto')
library('magrittr')
library(profvis)

# ##################################################
# pipe vs no pipe, and other methods comparisons

sampleEffort1 <- c(
  cost=function (x) x*2
  ,min=1.0,max=3.0
)
sampleEffort2 <- c(
  cost=function (x) x*5
  ,max=8
)

SampleEfforts <- list()
sampleEffort1$weight <- 1
sampleEffort2$weight <- 2
SampleEfforts[[length(SampleEfforts)+1]] <- sampleEffort1
SampleEfforts[[length(SampleEfforts)+1]] <- sampleEffort2

iterations <- 1000

f00 <- function () {
  for(i in 1:iterations)
        sum(
          unlist(
            lapply(
              seq_along(SampleEfforts),
              function(x) effort.weight(SampleEfforts[[x]],
                                        effort.normalize(SampleEfforts[[x]],
                                                         effort.compute(SampleEfforts[[x]], 1)))
        )))
}

f0 <- function () {
  for(i in 1:iterations)
        sum(unlist(lapply(seq_along(SampleEfforts), function(x)
          effort.compute(SampleEfforts[[x]], 1)
            %>% effort.normalize(SampleEfforts[[x]],.)
            %>% effort.weight(SampleEfforts[[x]],.)
        ) ) )
}

f1 <- function () {
  for(i in 1:iterations)
        lapply(seq_along(SampleEfforts), function(x)
          effort.compute(SampleEfforts[[x]], 1)
            %>% effort.normalize(SampleEfforts[[x]],.)
            %>% effort.weight(SampleEfforts[[x]],.)
        ) %>% unlist %>% sum
}


f2 <- function () {
  for(i in 1:iterations)
        (seq_along(SampleEfforts) %>% lapply(., function(x)
                effort.compute(SampleEfforts[[x]], 1)
                %>% effort.normalize(SampleEfforts[[x]],.)
                %>% effort.weight(SampleEfforts[[x]],.)
            ) %>% cumsum)[-1]
}


f3 <- function () {
  for(i in 1:iterations)
        seq_along(SampleEfforts) %>% lapply(., function(x)
                effort.compute(SampleEfforts[[x]], 1)
                %>% effort.normalize(SampleEfforts[[x]],.)
                %>% effort.weight(SampleEfforts[[x]],.)
            ) %>% Reduce('+', .)
}

f4 <- function () {
  for(i in 1:iterations)
            seq_along(SampleEfforts) %>% lapply(., function(x)
              matrix(c(
                effort.compute(SampleEfforts[[x]], 1)
                %>% effort.normalize(SampleEfforts[[x]],.)
                %>% effort.weight(SampleEfforts[[x]],.)
                ,
                SampleEfforts[[x]]$max*SampleEfforts[[x]]$weight
              ),1,2)
            ) %>% Reduce('+', .)
}



allf1 <- function() {
f4();f2();f0();f3();f00();f1();}

# ##################################################
# modulus versus condition checking

iterations <- 100000
modulus <- function(){
 for(i in 1:iterations)
   for(x in 1:30)
    a<- (x-1) %% 10 < 5
#print(a)
}

noModulus <- function(){
 for(i in 1:iterations)
      for(x in 1:30)
       a<- x<=5 || (x>10 && x<=15 ) || (x>20 && x<=25 )
#print(a)
}

allf2 <- function() {
noModulus(); modulus();
}


# ##################################################
# loops, pre computing and matrix operations comparison


iterations <- 100
sample_layout <- array (c (1:29), dim=29)

bigram.cost1 <- function (layout)
   for(i in 1:iterations)
{
  cost <- 0
  for(first_letter in 1:26)
  for(second_letter in 1:26)
    cost <- cost + bigram.bigram_cost(layout[first_letter],layout[second_letter]) * bigrams_freq[second_letter,first_letter]
}

bigram.cost2 <- function (layout) # should not differ much from 1 because costs and freqs are iterated ortogonaly to each other
 for(i in 1:iterations)
{
  cost <- 0
  for(second_letter in 1:26)
  for(first_letter in 1:26)
    cost <- cost + bigram.bigram_cost(layout[first_letter],layout[second_letter]) * bigrams_freq[second_letter,first_letter]
}


t_bigrams_freq <- t(bigrams_freq)
bigram.cost12 <- function (layout)
 for(i in 1:iterations)
{
  cost <- 0
  for(first_letter in 1:26)
  for(second_letter in 1:26)
    cost <- cost + bigram.bigram_cost(layout[first_letter],layout[second_letter]) * t_bigrams_freq[first_letter,second_letter]
}

bigram.cost22 <- function (layout)
 for(i in 1:iterations)
{
  cost <- 0
  for(second_letter in 1:26)
  for(first_letter in 1:26)
    cost <- cost + bigram.bigram_cost(layout[first_letter],layout[second_letter]) * t_bigrams_freq[first_letter,second_letter]
}


#pre compute all possible values
bigram.pre_computed_costs <- matrix(0,nrow = 30, ncol = 30)
  for(fp in 1:30)#1st letter position
  for(sp in 1:30)#2nd letter position
    bigram.pre_computed_costs[fp,sp] <- bigram.bigram_cost(fp, sp)
#print(bigram.pre_computed_costs )


bigram.cost3 <- function (layout)
 for(i in 1:iterations)
{
  cost <- 0
  for(second_letter in 1:26)
  for(first_letter in 1:26)
    cost <- cost + bigram.pre_computed_costs[layout[first_letter],layout[second_letter]] * bigrams_freq[second_letter,first_letter]
}

auxL <- matrix(c(1:26))
auxF <- function(s, f, layout) bigram.pre_computed_costs[layout[f],layout[s]] * bigrams_freq[s,f]
bigram.cost4 <- function (layout)
 for(i in 1:iterations)
{
  cost <- 0
  for(first_letter in 1:26)
    cost <- cost + sum(apply(auxL, 1, auxF,first_letter,layout))

  #return(cost)
}

auxF2 <- function(s, f, layout) bigram.pre_computed_costs[layout[f],layout[s]] * t_bigrams_freq[f,s]
bigram.cost42 <- function (layout)
  for(i in 1:iterations)
{
  cost <- 0
  for(first_letter in 1:26)
    cost <- cost + sum(apply(auxL, 1, auxF2,first_letter,layout))

  #return(cost)
}


auxF21 <- function(s, f) bigram.pre_computed_costs[sample_layout[f],sample_layout[s]] * bigrams_freq[s,f]
auxF12 <- function(s, f) bigram.pre_computed_costs[sample_layout[f],sample_layout[s]]
bigram.cost5 <- function (layout)
   for(i in 1:iterations)
     sum(outer(1:26, 1:26, Vectorize(auxF21)))

bigram.cost6 <- function (layout)  #R should optimize multiplication so this should be cache friendly
   for(i in 1:iterations)
     sum(outer(1:26, 1:26, Vectorize(auxF12))*bigrams_freq)


#print("f1:")
#print(bigram.cost6(sample_layout))
#print("f2:")
#print(bigram.cost4(sample_layout))

allf3 <- function() {
   bigram.cost5(sample_layout);
  bigram.cost42(sample_layout);
  bigram.cost22(sample_layout);
bigram.cost6(sample_layout); bigram.cost2(sample_layout);
bigram.cost3(sample_layout); bigram.cost4(sample_layout);
    bigram.cost1(sample_layout);
  bigram.cost12(sample_layout);

}


# ##############################################
# ##############################################

profvis(allf3())

