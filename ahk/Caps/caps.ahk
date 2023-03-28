; __________________________________________________________________________
; 	User Config.
; __________________________________________________________________________

;If you use more than one language or keyboard layout
; you may want to deactivate language/layout switch shortcuts

ProgrammerCommands := False ;Set to True to allow programmer related commands (see in documentation)


; --- Auto Mode Options ---
global x := True        ; start off script with an assumed capital (true)
global R := True        ; always capitalize after typing return
global E := "{Return}"  ; list of end-keys to trigger capitalizing
global C := True        ; add space after comma
global D := True        ; add space after colon or semicolon


global  ExcludedPrograms := ["devenv"]  
;"devenv"]
; List of program names to bypass clipboard check .
; This will deactivate change selected text or line functionality on listed programs.
; You will only be able to edit the previous word. 
;  e.g. in visual studio Ctrl+C copies a line and so
;  		it is not possible to change a word without
;       making a selection manually...

; __________________________________________________________________________
; __________________________________________________________________________

AutoMode := False ; there is no need to change this, just press RAlt & CapsLock to activade/deactivate

; set script icon
;Menu Tray, Icon, imageRes.dll, 117

; load icons 
icon := ".\cap.ico" 
iconLazyMode := ".\cap2.ico" 
Menu, Tray, Icon, %icon%


HasVal(haystack, needle) {
    for index, value in haystack
        if (value = needle)
            return index
    if !(IsObject(haystack))
        throw Exception("Bad haystack!", -1, haystack)
    return 0
}
; __________________________________________________________________________
; Cap Mods
;    Use mod keys with caps to change to lower/upper case certain letters
; __________________________________________________________________________

MaybeSelectPrevious(){
 ;auxiliar method that checks whether there is any text selected. Then:
 ; if there is, then this method does nothing, so that the selection is changed
 ; if there is not, this method will select a word or text segment depending on whether shift is pressed or not
 
 WinGet, OutputVar, ProcessName, A
 SplitPath, OutputVar,,,, OutNameNoExt
 ;Msgbox % OutNameNoExt
 ;Msgbox % HasVal(ExcludedPrograms,OutNameNoExt)

 if (! HasVal(ExcludedPrograms,OutNameNoExt))
 {
	;MsgBox, a1
	Clipboard := ""     ; empty clipboard
	Send, ^c            ; copy selection if any
	ClipWait, 0.06      ; wait for the clipboard to contain data
	if (ErrorLevel=0) 
	{
		;MsgBox, a2
		return     ; if found data in the clipboard return
	}	
	
	if GetKeyState("Shift")
	{
		;when using VS
		;this works most of the times, but not always, so to avoid confusion, I disable it.
		Send, +{Home}   ; select all text behind the cursor on the current line
		return
	}
 }
   ; no clip found and shift was not pressed.
   ; or the application is in the excluded list and the other functionalities are disabled
   Send, ^+{Left}  ; select the word behind the cursor
 
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
; Programming conventions conversion
; __________________________________________________________________________



#if ProgrammerCommands
^Insert::                ; Convert snake_case to camelCase (may convert from kebab if using a selection)
^+Insert::
 ClipSaved := ClipboardAll ;save clipboard

 MaybeSelectPrevious()
 Send, ^x
 ClipLen1 := StrLen(Clipboard)
 Clipboard := RegExReplace(Clipboard, "([_-])([A-Za-z])", "$u2")
 ClipLen2 := StrLen(Clipboard)
 if (ClipLen1 == ClipLen2)  
 {
    if ( RegExMatch(Clipboard, "(?:^)[a-z]") )
    {
        Clipboard := RegExReplace(Clipboard, "((?:^)[a-z])", "$u1")
    }
    else if ( RegExMatch(Clipboard, "(?:^)[A-Z]") )
    {
        Clipboard := RegExReplace(Clipboard, "((?:^)[A-Z])", "$l1")
    }
 }
 Send, ^v
  
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN


#if ProgrammerCommands
!Insert::                ; Convert camelCase to snake_case (may convert from kebab if using a selection)
!+Insert::
 ClipSaved := ClipboardAll ;save clipboard

 MaybeSelectPrevious()
 Send, ^x
 Clipboard := RegExReplace(Clipboard, "([a-z])([A-Z])", "$1_$l2")
 Clipboard := RegExReplace(Clipboard, "[\-]([A-Za-z])", "_$l1")
 StringLower Clipboard, Clipboard
 Send, ^v
  
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN


#if ProgrammerCommands
^!Insert::                ; convert camelCase or snake_case to to kebab-case
^!+Insert::
 ClipSaved := ClipboardAll ;save clipboard
 
 MaybeSelectPrevious()
 Send, ^x
 Clipboard := RegExReplace(Clipboard, "([a-z])([A-Z])", "$1-$l2")
 Clipboard := RegExReplace(Clipboard, "[_]([A-Za-z])", "-$1")
 Send, ^v
 
 ;restore clipboard
 Clipboard := ClipSaved 
 ClipSaved := ""
RETURN


; __________________________________________________________________________
; Auto Mode
;    Auto mode allows to auto inputs spacing and caps.
; __________________________________________________________________________

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
