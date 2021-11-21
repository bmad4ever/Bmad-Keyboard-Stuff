; ToggleTriggerSpam

; This script sets a "spam" key as being pressed whenever a "trigger" key is being pressed.
; A toggle key is used to activate or deactivate the described behavior.
; The user can define: the toggle key; the spam key; and a set of trigger keys.


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

; toggle key
ToggleKey := "*$Shift"

; the key you want to SPAM
SpamKey := "Shift"

; list of trigger keys that send the SpamKey when SPAM MODE is ON
TriggerKeys := ["w","a","s","d","LCtrl","Space"] 

; Set to false to hide spam mode icon
ShowIcon := false


;----------------------------------------
;   INITIAL SETUP
;----------------------------------------

; setup auxiliary variables
previous_trigger := false
trigger := false
ToggleKeyUp := ToggleKey " up"
Spam := False 

; setup main loop
SetTimer, update, 1

; setup toggle
Hotkey, %ToggleKey%, toggle_spam, On 
Hotkey, %ToggleKeyUp%, do_nothing, On 

return


;----------------------------------------
;   FUNCTIONS
;----------------------------------------

toggle_spam:
  global Spam
  global x
  global y
  global iconSize
  global trigger
  global ShowIcon
  

  Spam := !Spam
  trigger := false
    
  if Spam{
    if ShowIcon
        Gui ICO:Show , w%iconSize% h%iconSize% x%x% y%y% NoActivate, icoW
  }
  else{
    Send % "{Blind}{" . SpamKey . " up}"
    if ShowIcon
        Gui ICO:Hide
  }
return

;------------------------------------
do_nothing:
return

;------------------------------------
update:
 global Spam
 
 Loop
 {
  if Spam
    CheckAndSpam()
  sleep, 10
 }
return

;------------------------------------
CheckAndSpam(){
 global SpamKey
 global TriggerKeys
 global trigger
 global previous_trigger
 
 previous_trigger := trigger
 trigger := false
 for index, key in TriggerKeys 
 {
    if( GetKeyState(key, "P") ){
      trigger := true
      break
      }
 }
 if(trigger != previous_trigger)
 {
     if trigger
       Send % "{Blind}{" . SpamKey . " down}" 
     else
       Send % "{Blind}{" . SpamKey . " up}" 
 }
}