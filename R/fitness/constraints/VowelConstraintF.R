# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 19/07/2021

letter2number <- function(x) {utf8ToInt(x) - utf8ToInt("A") + 1L}
isLeftHand <- function (key_pos) key_pos<=5 || (key_pos>10 && key_pos<=15 ) || (key_pos>20 && key_pos<=25 )

vowels_in_left_hand <- function(layout){
 return(  isLeftHand(layout[letter2number('A')]) &&
          isLeftHand(layout[letter2number('I')]) &&
          isLeftHand(layout[letter2number('U')]) &&
          isLeftHand(layout[letter2number('E')]) &&
          isLeftHand(layout[letter2number('O')])
 )}

contraint.vowels <- c(
  constraint=vowels_in_left_hand,
  penalty=0.1
)
