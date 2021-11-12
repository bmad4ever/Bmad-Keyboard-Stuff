; ToggleTriggerSpam

; This script sets a "spam" key as being pressed whenever a "trigger" key is being pressed.
; A toggle key is used to activate or deactivate the described behavior.
; The user can define: the toggle key; the spam key; and a set of trigger keys.
;
; The toggle Key won't be sent when pressed and may be different from SPAM key.
; You may change this behavior by slightly modifying the toggle implementation.

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
;   BEHAVIOR
;----------------------------------------

; Indicates whether SPAM MODE is ON or OFF 
Spam := False 

; list of trigger keys that send the SpamKey when SPAM MODE is ON
TriggerKeys := ["w","a","s","d","LCtrl","Space"] 

; the key you want to SPAM
SpamKey := "Shift"

; setup main loop
SetTimer, update, 1

; SPAM MODE toggle key
*$Shift::
  global Spam
  global x
  global y
  global iconSize
  
  Spam := !Spam
  if Spam 
    Gui ICO:Show , w%iconSize% h%iconSize% x%x% y%y% NoActivate, icoW
  else
    Gui ICO:Hide
return


; ////////////  MAIN LOOP  /////////////
update:
 global Spam
 global SpamKey
 global TriggerKeys
 ;MsgBox, OK
 trigger := false 
 Loop
 {
  if Spam
  {
    previous_trigger := trigger
    trigger := false
    for index, key in TriggerKeys 
    {
       if( GetKeyState(key, "P") ){
         ;MsgBox, OOO
         trigger := true
         break
         }
    }
    if(trigger != previous_trigger)
    {
        ;MsgBox, OKAY
        if trigger
          Send % "{Blind}{" . SpamKey . " down}" 
        else
          Send % "{Blind}{" . SpamKey . " up}" 
    }
  }
  sleep, 10
 }
 
  