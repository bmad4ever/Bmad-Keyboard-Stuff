; ToggleTriggerSpam4Controllers

; This scripts behaves as the original ToggleTriggerSpam (TTS) script,
; but also allows to trigger the spam via analog stick.
; The used joystick is auto detected by default.
;
; The key to be spammed is, by default, a keyboard key.
;
; vJoy can be used instead by setting the below variable to true.
; For missing stuff, check https://github.com/evilC/AHK-CvJoyInterface.
vJoy := false ;set to true 


myStick := 0
if vJoy
{
    #include CvJoyInterface.ahk
    ;#include <CvJoyInterface>
    
    ; Create an object from vJoy Interface Class.
    vJoyInterface := new CvJoyInterface()
    
    ; Was vJoy installed and the DLL Loaded?
    if (!vJoyInterface.vJoyEnabled())
    {
        ; Show log of what happened
        Msgbox % vJoyInterface.LoadLibraryLog
        return
    }
    
    myStick := vJoyInterface.Devices[1]
}

;----------------------------------------
;   GUI 
;----------------------------------------
Menu, Tray, Icon, spam.ico

iconSize := A_ScreenHeight // 15   ;in pixels

; Toggle icon position
x := A_ScreenWidth // 2 - iconSize // 2 
y := A_ScreenHeight - 2 * iconSize

Gui ICO: -caption -toolwindow -border +alwaysOnTop +LastFound +E0x08000000 +ToolWindow
Gui ICO: Add, Picture, w%iconSize% h%iconSize% x0 y0 AltSubmit BackGroundTrans, .\spam.ico

;make background transparent
Gui ICO: Color, 000111
Gui ICO: Show , w%iconSize% h%iconSize% x%x% y%y% NoActivate, icoW
WinSet, Transcolor, 000111, icoW
Gui ICO:Hide

;----------------------------------------
;   CONFIGS 
;----------------------------------------

; Set to false to hide spam mode icon
ShowIcon := true

; the threshold is relative to the distance to the center of the stick, 
;   and not to the value on each of the axis.
; Set to a value in the range of ]0,1[, 
;   the higher the value the higher the distance required to the center of the stick.
threshold_as_a_percentage := 0.1 

; Set the analog sticks that trigger the spam key 
; Note: this should work for most controllers, 
;       but you might need to fix the used axis,
;       you can use this script to find the correct axis:
;       https://www.autohotkey.com/docs/scripts/index.htm#JoystickTest
stick1 := true
stick2 := false

; Keys that will  trigger the spam key
; you can use the JoystickTest link above to findout the keys' names
TriggerKeys := ["Joy5", "Joy7"] 

; SPAM MODE toggle key
ToggleKey := "Joy11"

; the key you want to SPAM
if !vJoy
    SpamKey := "Shift" ;keyboard key
else
    SpamKey := 11      ;vJoy key


; Joystick to use. 
; If the default value - zero - is used,
;  the script will use the lowest numberered active joystick.
; If the number is specified then the script will force the usage of the specified joystick.
JoystickNumber := 0


;----------------------------------------
;   Setup behavior
;
;   Do not edit this unless you know what you're doing. 
;----------------------------------------

; Despite working with sticks this script is not ready for analog keys.
; To use analog keys tweak the script by uncommenting the line:
;           threshold2 := 100 * threshold_as_a_percentage
;
; Then, in the update 'function', after the line: 
;            trigger := false
; add the lines, and replace AXIS with your key axis:
;   if GetKeyState(JoystickNumber "JoyAXIS") > threshold2
;            trigger := true

threshold := 50*50 * threshold_as_a_percentage
;threshold2 := 100 * threshold_as_a_percentage

; Auto-detect the joystick number if called for:
if JoystickNumber <= 0
{
	Loop 16  ; Query each joystick number to find out which ones exist.
	{
		GetKeyState, JoyName, %A_Index%JoyName
		if JoyName <>
		{
			JoystickNumber = %A_Index%
			break
		}
	}
	if JoystickNumber <= 0
	{
		MsgBox The system does not appear to have any joysticks.
		ExitApp
	}
}


;update all key names
ToggleKey := JoystickNumber ToggleKey
for index, key in TriggerKeys 
    TriggerKeys[index]   := JoystickNumber key

; start main loop and add toggle event
Spam := false
SetTimer, update, 1
Hotkey, %ToggleKey%, toggle_spam, On   

return


;----------------------------------------
;   Functions 
;----------------------------------------

toggle_spam:
  global Spam
  global x
  global y
  global iconSize
  global ShowIcon
  global myStick
  
  Spam := !Spam
  trigger := false
    
  if Spam{
    if ShowIcon
        Gui ICO:Show , w%iconSize% h%iconSize% x%x% y%y% NoActivate, icoW
  }
  else{
    if vJoy
        myStick.SetBtn(0,SpamKey) 
    else
        Send % "{Blind}{" . SpamKey . " up}"
    if ShowIcon
        Gui ICO:Hide
  }
return
 

update:
 global Spam
 global SpamKey
 global TriggerKeys
 global myStick

 trigger := false 

 Loop
 {
  if Spam
  {
    previous_trigger := trigger
    trigger := false
    
    if stick1
    {
        GetKeyState, JoyX, %JoystickNumber%JoyX  ; Get position of X axis.
        GetKeyState, JoyY, %JoystickNumber%JoyY  ; Get position of Y axis.
     
        JoyY := JoyY - 50
        JoyX := JoyX - 50
        
        if JoyY*JoyY+JoyX*JoyX > threshold
            trigger := true
    }
    
    if stick2 and not trigger
    {
        GetKeyState, JoyR, %JoystickNumber%JoyR  ; Get position of X axis.
        GetKeyState, JoyZ, %JoystickNumber%JoyZ  ; Get position of Y axis.
     
        JoyR := JoyR - 50
        JoyZ := JoyZ - 50
        
        if JoyZ*JoyZ+JoyX*JoyX > threshold
            trigger := true
    }
    
    for index, key in TriggerKeys 
    {
       if( GetKeyState(key, "P") ){
         trigger := true
         break
         }
    }
        
    if(trigger != previous_trigger)
        {
            if vJoy
            {
                if trigger
                    myStick.SetBtn(1,SpamKey)
                else
                    myStick.SetBtn(0,SpamKey) 
            }
            else
            {
                if trigger
                    Send % "{" . SpamKey . " down}" 
                else
                    Send % "{" . SpamKey . " up}" 
            }
        }
        
  }
  sleep, 10
 }
 