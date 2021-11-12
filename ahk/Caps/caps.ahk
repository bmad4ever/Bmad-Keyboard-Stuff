; set script icon
;Menu Tray, Icon, imageRes.dll, 117

; load icons 
icon := ".\cap.ico" 
iconLazyMode := ".\cap2.ico" 
Menu, Tray, Icon, %icon%



; __________________________________________________________________________
; Cap Mods
;    Use mod keys with caps to change to lower/upper case certain letters
; __________________________________________________________________________

MaybeSelectPrevious(){
 ;auxiliar method that
 ;checks if there is text selected. Then:
 ;if there then this method does nothing, so that the selection is changed
 ;if there is not this method will select a word or text segment depending on whether shift is pressed or not

 clipboard := ""     ; empty clipboard
 Send, ^c            ; copy selection if any
 ClipWait, 0.06      ; wait for the clipboard to contain data
 
 if (ErrorLevel)     ; if clipwait did not find data on the clipboard
 {
   if GetKeyState("Shift")
   {
     Send, +{Home}    ; select all text behind the cursor on the current line
   }
   else
   {
     Send, ^+{Left}  ; select the word behind the cursor
   }
 }
 
 return
}




^CapsLock::                ; Convert to UPPER
^+CapsLock::
 ClipSaved := ClipboardAll ;save clipboard
 
 MaybeSelectPrevious()
 
 Send, ^x            ; cut selection
 StringUpper Clipboard, Clipboard
 Send, ^v
 
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN



!CapsLock::                ; Convert to lower
!+CapsLock::
 ClipSaved := ClipboardAll ;save clipboard
 
 MaybeSelectPrevious()
 Send, ^x            ; cut selection
 StringLower Clipboard, Clipboard
 Send, ^v
 
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN



^!CapsLock::                ; Convert to Capitalized
^!+CapsLock::
 ClipSaved := ClipboardAll ;save clipboard
 
 MaybeSelectPrevious()
 Send, ^x
 StringUpper Clipboard, Clipboard, T
 Send, ^v
 
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN



+CapsLock::            ; Sentence case
 ClipSaved := ClipboardAll ;save clipboard
 
 MaybeSelectPrevious()
 Send, ^x
 StringLower, Clipboard, Clipboard
 Clipboard := RegExReplace(Clipboard, "((?:^|[.?!]\s+)[a-z])", "$u1")
 Send, ^v
  
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN






; __________________________________________________________________________
; Auto Mode
;    Auto mode allows to auto inputs spacing and caps.
; __________________________________________________________________________

AutoMode := False
#if AutoMode
RAlt & CapsLock::            ; Deactivate Auto Mode
  AutoMode := False  
  Menu, Tray, Icon, %icon%
  
  ; workaround to unblock Input func
  ; will allow to turn mode on without any input being given after a deactivation
  ; I am not aware of any side effects
  Input  
RETURN



; following solution was addapted from 3rror answer found on ahk forum:
; https://autohotkey.com/board/topic/132938-auto-capitalize-first-letter-of-sentence/

#if not AutoMode
RAlt & CapsLock::            ; Activate Auto Mode
 AutoMode := True  

; set the icon that indicates auto mode is active
 Menu, Tray, Icon, %iconLazyMode%
 
; --- Auto Mode Options ---
 x := True        ; start off script with an assumed capital (true)
 R := True        ; always capitalize after typing return
 E := "{Return}"  ; list of end-keys to trigger capitalizing
 C := True        ; add space after comma
 D := True        ; add space after colon or semicolon
; --- ---  --- ---  --- ---  

 SetKeyDelay, -1  ; avoid lag related mistakes, such as multiple upper cases
 Loop
 {   
    Input, key, C1 I L1 V, %E%
    on_endkey := R ? InStr(ErrorLevel,"EndKey") : false
    
    if not AutoMode
        break
        
    ; when triggered and lower case:
    if( x && RegExMatch(key,"[a-z]") )
    {
        ; initialized, or there was a whitespace or return typed before this key
        if( !key_prev || key_prev = "EndKey" )
        {    
            Send {Backspace}+%key%
        
        }  ; or, if a number was not typed (don't interrupt typing float numbers)
        else if key is not integer
        {
            Send {Backspace}{Space}+%key%
        }
        x := False
    }
    else if( key != "" )  ; a non-EndKey
    {    
        x := False
        if InStr(".?!", key)
            x := True  ; trigger set
        else if (C && "," == key)
           Send {Space}
        else if (D && (":" == key || ";" == key))
           Send {Space}
           
        key_prev := key
    }
    else if on_endkey  ; Key is blank due to End-key matching
    {
        x := True  ; trigger set
        key_prev := "EndKey"
    }
 }

RETURN





