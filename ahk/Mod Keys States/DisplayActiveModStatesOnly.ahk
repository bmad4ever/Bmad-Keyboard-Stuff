#SingleInstance, force
#NoEnv
#Persistent

Menu, Tray, Icon, eye-open.ico

;setup gui ___________________________
guiActive:= True ;gui initial state

iconSize := A_ScreenHeight // 15   ;in pixels

;window only exists conceptually to enclose all symbols that may be on display
windowWidth := iconSize
windowHeight := iconSize*4

; Window position at the left upper corner 
; position at top center
x := A_ScreenWidth - windowWidth * 5 // 3 
y := A_ScreenHeight * 12 // 15 - windowHeight 

Gui, 1:-caption -toolwindow -border +alwaysOnTop +LastFound +E0x08000000 +ToolWindow
Gui, 1:Add, Picture, w%iconSize% h%iconSize% x0 y0 vShiftPic, .\ShiftOff.ico
 
Gui, 2:-caption -toolwindow -border +alwaysOnTop +LastFound +E0x08000000 +ToolWindow
Gui, 2:Add, Picture, w%iconSize% h%iconSize% x0 y0 vCtrlPic, .\CtrlOff.ico

Gui, 3:-caption -toolwindow -border +alwaysOnTop +LastFound +E0x08000000 +ToolWindow
Gui, 3:Add, Picture, w%iconSize% h%iconSize% x0 y0 vAltPic, .\AltOff.ico

Gui, 4:-caption -toolwindow -border +alwaysOnTop +LastFound +E0x08000000 +ToolWindow
Gui, 4:Add, Picture, w%iconSize% h%iconSize% x0 y0 vWinPic, .\WinOff.ico

SetTimer, update, 1
return



update:
 prevShown := [0,0,0,0]
 shown := [0,0,0,0]
 keys := ["Shift","Ctrl","Alt","LWin"]
 
 Loop
 {
  updateIt := False
  
  ;check mod keys states
  For k, v In keys
  {
    shown[k] := GetKeyState(v, "P")
    if k = 4
      shown[k] := shown[k] || GetKeyState("RWin", "P")
      
    if  !updateIt && shown[k] != prevShown[k] 
        updateIt := True
  }

  ;update guis if states changed
  if updateIt
  {
    yAux := y
    For k, v In shown
    {
     if v{
         Gui, %k%:Show , w%iconSize% h%iconSize% x%x% y%yAux% NoActivate
         yAux := yAux + iconSize
        }
     else
         Gui, %k%:Hide
         
     ;update prevShown for the next loop
     prevShown[k] := v
    }
  }
  
  sleep, 33
 }
return