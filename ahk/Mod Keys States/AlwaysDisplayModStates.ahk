#SingleInstance, force
#NoEnv
#Persistent


; set tray menu ____________
Menu, Tray, Icon, eye-open.ico

Menu, Tray, Standard
Menu, Tray, Add
Menu, Tray, Add, Show/Hide, ToggleGui
;Menu, Tray, Click, 1
;Menu, Tray, Tip, Your program description

;setup gui ___________________________
guiActive:= True ;gui initial state

iconSize := 24   ;in pixels

windowWidth := iconSize*5+2
windowHeight := iconSize+2

; Window position at the left upper corner 
; position at top center
x := A_ScreenWidth // 2 - windowWidth // 2
y := 0


Gui, -caption -toolwindow -border +alwaysOnTop +LastFound +E0x20
;Gui, Show , w110 h100, Window title

xAux := 1
Gui, Add, Picture, w%iconSize% h%iconSize% x%xAux% y1 vShiftPic, .\ShiftOff.ico
xAux := xAux + iconSize
Gui, Add, Picture, w%iconSize% h%iconSize% x%xAux% y1 vCtrlPic, .\CtrlOff.ico
xAux := xAux + iconSize
Gui, Add, Picture, w%iconSize% h%iconSize% x%xAux% y1 vAltPic, .\AltOff.ico
xAux := xAux + iconSize
Gui, Add, Picture, w%iconSize% h%iconSize% x%xAux% y1 vCapsPic, .\CapsLockOff.ico
xAux := xAux + iconSize
Gui, Add, Picture, w%iconSize% h%iconSize% x%xAux% y1 vWinPic, .\WinOff.ico

;Gui, Show, x%x% y%y%, NoActivate
Gui, Show , w%windowWidth% h%windowHeight% x%x% y%y%, NoActivate
SetTimer, update, 1
 
return



ToggleGui:
 guiActive := !guiActive
 if guiActive
    Gui, Show
 else
	Gui, Cancel
return



update:
 Loop
 {
  GetKeyState, state, Shift
  if (prevShift != state){
    if (state = "D")
        GuiControl,, ShiftPic, .\ShiftOn.ico
    else
        GuiControl,, ShiftPic, .\ShiftOff.ico
  }
  prevShift := state 
  
  GetKeyState, state, Ctrl
  if (prevCtrl != state){
  if (state = "D")
     GuiControl,, CtrlPic, .\CtrlOn.ico
  else
     GuiControl,, CtrlPic, .\CtrlOff.ico
  }
  prevCtrl := state   
   
  GetKeyState, state, Alt
  if (prevAlt != state){
  if (state = "D")
     GuiControl,, AltPic, .\AltOn.ico
  else
     GuiControl,, AltPic, .\AltOff.ico
  }
  prevAlt := state  
     
  state := GetKeyState("CapsLock", "T")
  if (prevCaps != state){
  if (state)
     GuiControl,, CapsPic, .\CapsLockOn.ico
  else
     GuiControl,, CapsPic, .\CapsLockOff.ico
  }
  prevCaps := state    

  state := GetKeyState("LWin", "P")
  state := state | GetKeyState("RWin", "P")
  if (prevWin != state){
  if (state)
     GuiControl,, WinPic, .\WinOn.ico
  else
     GuiControl,, WinPic, .\WinOff.ico
  }
  prevWin := state  
     
  sleep, 33
 }
return