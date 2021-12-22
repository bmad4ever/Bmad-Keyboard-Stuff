#SingleInstance, Off ;

Coordmode, Mouse, Screen
Coordmode, Tooltip, Screen

Gui, Add, Text,, Choose Target Joystick
Gui, Add, DropdownList,vTargetJoystick,1||2|3|4|5
Gui,Add,Button,gOk wp,Ok
Gui, Show,,This is the title
return

Ok:
Gui,Submit ;Remove Nohide if you want the GUI to hide.
;=======================================
; CONFIG
;=======================================

; UNTESTED for screens other than 1!!!
TargetScreen:= 1

;Joystick key used to turn controls off/on
ToggleKey := 10

;Joystick key to be used as left mouse click
LeftClick := 5

;Joystick key to be used as right mouse click
RightClick := 6

;The joystick axis responsible for mouse movement, horizontally and vertically respectively.
xAxis:= "JoyX"
yAxis:= "JoyY"

;Complementary options for mouse movement
invertXaxis:= false
invertYaxis:= false
threshold:= 5

;offset given for the starting position with respect to TargetJoystick
JoyDependantStartingXOffset:= 50


;----------------------------------------
;   Setup auxiliary variables 
;----------------------------------------

; Get target screen bounds
aux:= (TargetScreen-1)*2
SysGet, aScreenWidth  , %aux%
aux:= aux+1
SysGet, aScreenHeight , %aux%

threshold_squared:=threshold*threshold

ScaleFactorX := aScreenWidth / 5000
ScaleFactorY := aScreenHeight / 5000

vx:= aScreenWidth/2+ JoyDependantStartingXOffset*(-3.5+TargetJoystick)
vy:= aScreenHeight/2

;store key states and previous state on the loop
lcs  := 0
rcs  := 0
tg   := 0
plcs := 0
prcs := 0
ptg  := 0

;indicates whether the joystick control is enabled/disabled
active := true

;----------------------------------------
;   Setup GUI 
;----------------------------------------
icons:=["Red","Green","Cyan","Yellow","Purple"]
icon:= ".\mouse" icons[TargetJoystick] ".ico"
Menu, Tray, Icon, %icon%

iconSize := aScreenHeight // 50   ;in pixels
vx_gui := vx - iconSize/2
vy_gui := vy - iconSize/2

Gui ICO: +LastFound +AlwaysOnTop -Caption +E0x20 ; 
Gui ICO: Add, Picture, w%iconSize% h%iconSize% x0 y0 AltSubmit BackGroundTrans, %icon%

;make background transparent
Gui ICO: Color, 000111
;Gui ICO: Show , w%iconSize% h%iconSize% x100 y100 NoActivate, icoW
Gui ICO: Show , w%iconSize% h%iconSize% x%vx_gui% y%vy_gui% NoActivate, icoW
WinSet, Transcolor, 000111, icoW

;=======================================
; MAIN LOOP
;=======================================

Loop {
    
    ptg:= tg
    tg := GetKeyState(TargetJoystick "Joy" ToggleKey ,"P")
    
    if (tg and !ptg)
    {
        active := !active
        if active
            ToolTip,,,, %TargetJoystick%
        else
            ToolTip, off , %vx%, %vy%, %TargetJoystick%
    }
    
    if (!active)
        continue
    
    
    ;Get mouse movement
    GetKeyState, JoyX, %TargetJoystick%JoyX 
    GetKeyState, JoyY, %TargetJoystick%JoyY 
    
    x := (JoyX-50) * ScaleFactorX
    y := (JoyY-50) * ScaleFactorY
    
    if invertXaxis
        x := -x
    if invertYaxis
        y := -y
    
    
    ;update if above the threshold
    if (threshold_squared < x*x + y*y)
    {
        vx := vx + x
        vy := vy + y
        
        if (vx > aScreenWidth)
            vx := aScreenWidth
        if vx < 0
            vx := 0
        if (vy > aScreenHeight)
            vy := aScreenHeight
        if vy < 0
            vy := 0    
    
        vx_gui := vx - iconSize/2
        vy_gui := vy - iconSize/2
        Gui ICO: Show , w%iconSize% h%iconSize% x%vx_gui% y%vy_gui% NoActivate, icoW
    }
    
    ;Check left and righ buttons triggers
    lcs := GetKeyState(TargetJoystick "Joy" LeftClick ,"P")
    rcs := GetKeyState(TargetJoystick "Joy" RightClick,"P")
    
    ;update position 
    if (lcs or rcs)
        MouseMove, vx, vy, 0 

    if (lcs != plcs)
    {
        if ( lcs )
            Click, Left Down
        else
            Click, Left Up
    }
   
    if (rcs != prcs)
    {
        if ( rcs )
            Click, Down Right
        else
            Click, Up Right
    } 
       
    plcs := lcs
    prcs := rcs
    
    Sleep 20
}









