; CONFIGS

layer_mod_key := "LAlt"

;base layer

; configuration for pt laptop keyboard using us english qwerty layout
; [q][w][e][r][t][y][u][i][o][p][*+¨][`´]]
;   [a][s][d][f][g][h][j][k][l][ç][ªº][^~]
; [<>][z][x][c][v][b][n][m][;,][:.][_-]
row1 := { "q":"'", "w":"y", "e":"o", "r":"f", "t":";",             "y":"j", "u":"c", "i":"l", "o":"p", "p":","}
row2 := { "a":"h", "s":"i", "d":"e", "f":"a", "g":"u",             "h":"d", "j":"s", "k":"t", "l":"n", ";":"r"}
row3 := {"xx":"q", "z":"x", "x":".", "c":"k", "v":"z",  "b":"/",   "n":"w", "m":"g", ",":"m", ".":"b", "/":"v"}

; Symbol layer

row1s := { "q":"|", "w":"&", "e":"*", "r":":", "t":"^",             "y":"^", "u":"#", "i":"$", "o":"%", "p":""""}
row2s := { "a":"!", "s":"/", "d":"-", "f":"=", "g":"~",             "h":"~", "j":"{", "k":"(", "l":"[", ";":"?"}
row3s := {"xx":"+", "z":"<", "x":">", "c":"_", "v":"/",  "b":"/",   "n":"/", "m":"}", ",":")", ".":"]", "/":"\"}


; --------------------------------
;           Keymaps
; --------------------------------

*$q:: 
  if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["q"]
  else 
    Send % "{Blind}" . row1["q"]
return


*$w::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["w"]
    else
    Send % "{Blind}" . row1["w"]
return

*$e::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["e"]
    else
    Send % "{Blind}" . row1["e"]
return

*$r::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["r"]
    else
    Send % "{Blind}" . row1["r"]
return

*$t::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["t"]
    else
    Send % "{Blind}" . row1["t"]
return

*$y::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["y"]
    else
    Send % "{Blind}" . row1["y"]
return

*$u::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["u"]
    else
    Send % "{Blind}" . row1["u"]
return

*$i::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["i"]
    else
    Send % "{Blind}" . row1["i"]
return

*$o::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["o"]
    else
    Send % "{Blind}" . row1["o"]
return

*$p::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row1s["p"]
    else
    Send % "{Blind}" . row1["p"]
return


; 2nd row

*$a::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["a"]
    else
    Send % "{Blind}" . row2["a"]
return

*$s::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["s"]
    else
    Send % "{Blind}" . row2["s"]
return

*$d::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["d"]
    else
    Send % "{Blind}" . row2["d"]
return

*$f::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["f"]
    else
    Send % "{Blind}" . row2["f"]
return

*$g::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["g"]
    else
    Send % "{Blind}" . row2["g"]
return

*$h::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["h"]
    else
    Send % "{Blind}" . row2["h"]
return

*$j::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["j"]
    else
    Send % "{Blind}" . row2["j"]
return

*$k::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["k"]
    else
    Send % "{Blind}" . row2["k"]
return

*$l::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s["l"]
    else
    Send % "{Blind}" . row2["l"]
return

*$`;::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row2s[";"]
    else
    Send % "{Blind}" . row2[";"]
return


; 3rd row

*$SC056::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["xx"]
    else
    Send % "{Blind}" . row3["xx"]
return

*$z::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["z"]
    else
    Send % "{Blind}" . row3["z"]
return

*$x::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["x"]
    else
    Send % "{Blind}" . row3["x"]
return

*$c::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["c"]
    else
    Send % "{Blind}" . row3["c"]
return

*$v::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["v"]
    else
    Send % "{Blind}" . row3["v"]
return

*$b::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["b"]
    else
    Send % "{Blind}" . row3["b"]
return

*$n::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["n"]
    else
    Send % "{Blind}" . row3["n"]
return

*$m::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["m"]
    else
    Send % "{Blind}" . row3["m"]
return

*$,::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s[","]
    else
    Send % "{Blind}" . row3[","]
return

*$.::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["."]
    else
    Send % "{Blind}" . row3["."]
return

*$/::
    if GetKeyState(layer_mod_key, "P")
    SendRaw % row3s["/"]
    else
    Send % "{Blind}" . row3["/"]
return

