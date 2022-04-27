# Title     : TODO
# Objective : TODO
# Created by: Bruno
# Created on: 19/07/2021

# letter 26, "." , "," , ";" , "-"

force_symbol_position <- function(layout){
 return( #layout[27]==  &&# no restriction for period symbol...
         layout[28]==10 &&# due to same finger approach, no combos for comma
         layout[29]==5  &&# 4 ez specials
         layout[30]==1    # 4 ez specials
 )}

contraint.symbol <- c(
  constraint=force_symbol_position,
  penalty=0.1
)