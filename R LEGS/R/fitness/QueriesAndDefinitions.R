# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 21/04/2022


finger_map <- read.table("data/finger_map.txt", header=FALSE, sep=" ")
finger_map <- as.vector(t(finger_map))


finger <- c(
  #Use in arguments that need hand specification on the fingers argument
left_pinky = 1,
left_ring = 2,
left_middle = 3,
left_index = 4,
right_pinky = 9 - 1, #5
right_ring = 9 - 2 ,  #6 ...
right_middle = 9 - 3,
right_index = 9 - 4,
  #Use in arguments which use a separate argument for the hand
pinky = 1 ,
ring  = 2  ,
middle= 3,
index = 4 )

hand<-c(
  left = TRUE,
  right = FALSE
)


is_pinky<-function(key_pos)  finger_map[key_pos] == finger['left_pinky'] || finger_map[key_pos] == finger['right_pinky']
is_ring<-function(key_pos)  finger_map[key_pos] == finger['left_ring'] || finger_map[key_pos] == finger['right_ring']
is_middle<-function(key_pos)  finger_map[key_pos] == finger['left_middle'] || finger_map[key_pos] == finger['right_middle']
is_index<-function(key_pos)  finger_map[key_pos] == finger['left_index'] || finger_map[key_pos] == finger['right_index']


ignoreHand<-function(finger) {
#' @title ignoreHand: QueriesAndDefinitions
#' @description Convert a hand specific finger value to a hand agnostic finger value.
#' @examples
#'  input: right_ring (7) -> output: ring 2
     if(finger>4)
       return( 9 - finger )
  return(finger)
}

isSameKey <- function(key1_pos, key2_pos) key1_pos == key2_pos
isSameFinger <- function(key1_pos, key2_pos) finger_map[key1_pos] == finger_map[key2_pos]

isHomeRow <- function (key_pos) key_pos>10 && key_pos < 21

isLeftHand <- function (key_pos) key_pos<=5 || (key_pos>10 && key_pos<=15 ) || (key_pos>20 && key_pos<=25 )
areSameHand <- function (key_pos1, key_pos2) isLeftHand(key_pos1) == isLeftHand(key_pos2)
isSingleHandNGram <- function(...)  reduce(c(...), areSameHand)


areTheseFingersUsed<-function( fingers_to_check, ...) {
#' @title areTheseFingersUsed: QueriesAndDefinitions
#' @description Checks if a set of fingers is used in a n-gram (using hand dependant finger values).
#' @param fingers_to_check hand dependant finger values to check (1 checks for left pinky, 8 checks for right pinky)
#' @param ... key positions to check for.
  return (
    is.na(match(NA, match(fingers_to_check, unique(finger_map[c(...)]) ) ))
  )
}

areTheseFingersUsed2<-function( fingers_to_check, hand_to_check, ...){
#' @title areTheseFingersUsed2: QueriesAndDefinitions
#' @description Checks if a set of fingers is used in a n-gram (using hand agnostic finger values, but checking for the specified hand).
#' @param fingers_to_check hand independant finger values to check (1 checks for left or right pinky depending on hand_to_check)
#' @param hand_to_check the target hand to check for.
#' @param ... key positions to check for.
  if(!hand_to_check)
    fingers_to_check<-sapply(fingers_to_check, function (e) 9-e)
  return( is.na(match(NA, match(fingers_to_check, unique(finger_map[c(...)]) ) )) )
  }

getKeyPosIndex<-function(row, column) {
#' @title getKeyPosIndex: QueriesAndDefinitions
#' @description Gets the index of the fiven key position.
#' @param row Row index, starting at 1 -> [1,3].
#' @param column Row index, starting at 1 -> [1,10]
#' @return Key index, starting at 1.
  return((row-1)*10 + column)
}

getKeyPosRowColumn<-function(index) {
#' @title getKeyPosRowColumn: QueriesAndDefinitions
#' @description Convert a key's position index to its the column and row on a layout.
#' @param index Key index, starting at 1.
#' @return Key row column index pairs starting at 1, R like -> ( [1,3], [1,10] ).
  return (
    c(1+(index-1)%/%10, 1+(index-1)%%10)
    )
}

getKeyPosRow<-function(index){
#' @title getKeyPosRow: QueriesAndDefinitions
#' @description Convert a key's position index to its row on a layout.
#' @param index Key index, starting at 1.
  return( 1 +  (index-1)%/%10 )
}

getKeyPosColumn<-function(index) {
#' @title getKeyPosColumn: QueriesAndDefinitions
#' @description Convert a key's position index to its column on a layout.
#' @param index Key index, starting at 1.
  return( c(1+  (index-1)%/%10, 1+  (index-1)%%10) )
}

getRowDifference <- function(key1_pos, key2_pos) {
#' @title getRowDifference: QueriesAndDefinitions
#' @description Gets the row difference between 2 key position indexes.
#' @param key1_pos 1st key position index, starting at 1.
#' @param key2_pos 2nd key position index, starting at 1.
#' @return Row difference between the 2 keys where a negative sign indicates that the 2nd key is below the 1st key.
  return(
    (key1_pos-1)%/%10 - (key2_pos-1)%/%10
  )
}

getAbsColDifference <-function(key1_pos, key2_pos)  {
#' @title getAbsColDifference: QueriesAndDefinitions
#' @description Gets the column difference between 2 key position indexes.
#' @param key1_pos 1st key position index, starting at 1.
#' @param key2_pos 2nd key position index, starting at 1.
#' @return Column difference between the 2 keys (unsigned value)
  return (
    abs( (key1_pos-1)%%10 - (key2_pos-1)%%10 )
  )
}

getColDifferenceSameHand <-function(key1_pos, key2_pos, areLeftHand){
#' @title getColDifferenceSameHand: QueriesAndDefinitions
#' @description Similar to getAbsColDifference BUT the resulting sign will depend on the used hand. Both given keys should be typed with the same hand.
#' DISCLAIMER: ONLY works under the supposition that both keys use the same hand (doesn't check that condition).
#' @param areLeftHand Indicates what hand is responsible for both keys (should already have been checked before calling this function, so no need to recheck it).
#' @return Colum difference where a negative sign indicates an inward roll from the 1st to the 2nd key (positive sign indicates outward roll)
  if(areLeftHand)
    return( (key1_pos-1)%%10 - (key2_pos-1)%%10 )
  else
    return( (key2_pos-1)%%10 - (key1_pos-1)%%10 )
}

keysDistM <- function(key1_pos, key2_pos){
#' @title keysDistM: QueriesAndDefinitions
#' @description Manhattan distance between 2 given keys' positions in the keys matrix (not on the real keyboard)
  getAbsColDifference(key1_pos, key2_pos) + abs(getRowDifference(key1_pos, key2_pos))
}

keysDistE <- function(key1_pos, key2_pos){
#' @title keysDistM: QueriesAndDefinitions
#' @description Euclidean distance between 2 given keys' positions in the keys matrix (not on the real keyboard)
  d1<-getAbsColDifference(key1_pos, key2_pos)
  d2<-abs(getRowDifference(key1_pos, key2_pos))
  return ( sqrt(d1^2 + d2^2) )
}
