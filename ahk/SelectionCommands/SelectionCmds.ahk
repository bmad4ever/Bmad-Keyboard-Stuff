; -----------------------------------------------------------------------
;     KEY MAPS			KEY MAPS			KEY MAPS		KEY MAPS
; -----------------------------------------------------------------------

; TRIGGER KEY! ; which needs to be pressed for any command to occur
trigger := "F22" 


trigger_p := trigger " & "   ; do not change this line
OP_ADD_LS := 0				 ; do not change this line
OP_EXP := 1					 ; do not change this line
OP_ADD_MS := 2  			 ; do not change this line

KeyMap(trigger " Up", Func("SelectWord")) 

;            ______
; you may    _____ |
;   change        ||
;     these       ||
;       mappings \  /
;                 \/
KeyMap(trigger_p "Tab"       , Func("GoToOpen")) 
KeyMap(trigger_p "Space"     , Func("SelectTillClosed")) 
KeyMap(trigger_p "Enter"     , Func("OpenInFullScreen")) 
KeyMap(trigger_p "Backspace" , Func("ClearLine")) 
; - - - - - - -|             |- - - - - - - - - - - - - - - - - - - - - 
KeyMap(trigger_p "o Up"      , Func("AddSelection").Bind(1, OP_EXP)) 
KeyMap(trigger_p "e Up"      , Func("AddSelection").Bind(-1, OP_EXP)) 
KeyMap(trigger_p "a Up"      , Func("AddSelection").Bind(1, OP_ADD_LS)) 
KeyMap(trigger_p "i Up"      , Func("AddSelection").Bind(-1, OP_ADD_LS)) 
KeyMap(trigger_p "f Up"      , Func("AddSelection").Bind(1, OP_ADD_MS)) 
KeyMap(trigger_p "y Up"      , Func("AddSelection").Bind(-1, OP_ADD_MS)) 


; -----------------------------------------------------------------------
;     OTHER CONFIGS			OTHER CONFIGS			OTHER CONFIGS
; -----------------------------------------------------------------------
; time in milliseconds
delay_between_number_changes := 33


; maximum number of chars accepted, if clipboard exceeds it, the operation is canceled
; prevents getting stuck due to too much data
; only used in the following functions: GoToOpen; and SelectTillClosed
max_number_of_chars_in_clipboard := 512


; list of apps to use F11 in when using fullscreen open shortcut is used
; not all apps will work
apps_to_f11 := "brave|edge|cmd|mintty"
StringLower, apps_to_f11, apps_to_f11  ; I prefer to just ignore the casing, but may be a problem for some pair of apps

; -----------------------------------------------------------------------

; load icon
icon := ".\sc.ico" 
Menu, Tray, Icon, %icon%


; -----------------------------------------------------------------------
;     FUNCTIONS		FUNCTIONS			FUNCTIONS		FUNCTIONS
; -----------------------------------------------------------------------

KeyMap( key, func ){
	Hotkey %key%, % func
}


; select the word at the caret position (or mouse position for non editable areas) and return it
; considers numbers with decimal places ( only using dot, commas are ignored )
; adapted from mikagenic script in https://www.autohotkey.com/boards/viewtopic.php?t=23842 
SelectWord()
{
	ClipSaved := ClipboardAll

	; get letter on the left
	Clipboard :=
	SendInput +{Left}^c{Right}
	ClipWait, 0.1
	charLeft := Clipboard

	if (charLeft == "") { ; a non editable area
		CoordMode, Mouse, Screen
		MouseGetPos, X_1, Y_1, ID_1, Control_1 
		X_1 += 3 
		MouseMove, %X_1%, %Y_1% ; shift cursor a bit to prevent dblclick from selecting the whole line
		Click 2
		Clipboard :=
		SendInput, ^c
		X_1 -= 3 ; restore mouse
		MouseMove, %X_1%, %Y_1%
	
	} else { ; editable area
		Clipboard :=
		if (RegExMatch(charLeft,"[[:alnum:]]")) { ; char on the left is alphanumeric
			SendInput ^{Left}+^{Right}^c
		} else { ; char on the left is either space or punctuation
			SendInput +^{Right}^c
		}
		ClipWait, 0.1
		
		; unselect spaces on the right
		t := "x" Clipboard ; preserve   by adding non-space char
		t = %t%  ; autotrim trailing white-space
		nBlankOnRight := StrLen(Clipboard)-StrLen(t)+1
		if (nBlankOnRight>0) {
			Clipboard :=
			SendInput +{Left %nBlankOnRight%}^c
			ClipWait, 0.1
		}
		
		; all text selected here
		; check if all numbers
		if (RegExMatch(Clipboard,"[0-9]+")){
			; check to the right of the number
			; mind current selection has already been trimmed
			Clipboard:=
			SendInput {Right}+{Right}^c  ; cursor behind char before prior selection
			ClipWait 0.1
			charRight := Clipboard
			
			if (RegExMatch(charRight,"[.]")){
				; the number contains a dot to the right

				; get digits, if any
				Clipboard:=
				SendInput +^{Right}^c  ; cursor behind char before prior selection
				ClipWait 0.1
				
				; unselect spaces on the right
				t := "x" Clipboard ; preserve   by adding non-space char
				t = %t%  ; autotrim trailing white-space
				nBlankOnRight := StrLen(Clipboard)-StrLen(t)+1
				if (nBlankOnRight>0) {
					Clipboard :=
					SendInput +{Left %nBlankOnRight%}^c
					ClipWait, 0.1
				}
				
				if (RegExMatch(Clipboard,"[.][0-9]")){
					; has numbers to the right, append them to the original selection

					; reselect 1st selection
					Clipboard :=
					SendInput ^{Left}{Left}^{Left}+^{Right 3}^c
					ClipWait, 0.1
				}
				else{
					; ignore dot if no numbers to the right
					; go back to original selection
					Clipboard :=
					SendInput {Left}^{Left}+^{Right}^c
					ClipWait, 0.1
					; note: there is no need to trim in this specific case
					;	    maybe could make last trimming optional... not sure if worth it...
				}
				
			}
			else ; check to the left of the number
			{
				Clipboard:=
				SendInput {Left}^{Left}+{Left}^c  ; cursor behind char before prior selection
				ClipWait 0.1
				charLeft := Clipboard
				
				; will ignore sign here
				
				if (RegExMatch(charLeft,"[.]")){
					; there is a dot to the left of the number
				
					; get digits, if any
					Clipboard:=
					SendInput +^{Left}^c  
					ClipWait 0.1
					
					if (RegExMatch(Clipboard,"[0-9]+[.]"))
					{
						; has more digits behind the dot; select entire thing
						Clipboard :=
						SendInput {Left}+^{Right 3}^c
						ClipWait, 0.1
					}
					else 
					{
						; no other digits before the dot were found
						; suppose that the dot belongs to the number
						Clipboard :=
						SendInput ^{Right}+^{Right 2}^c
						ClipWait, 0.1
					}
				}
				else ; nothing to prepend/append to the number
				{
					; reset to original selection
					Clipboard :=
					SendInput {Right}+^{Right}^c
					ClipWait, 0.1
				}
			}
			
			; unselect spaces on the right
			t := "x" Clipboard ; preserve   by adding non-space char
			t = %t%  ; autotrim trailing white-space
			nBlankOnRight := StrLen(Clipboard)-StrLen(t)+1
			if (nBlankOnRight>0) {
				Clipboard :=
				SendInput +{Left %nBlankOnRight%}^c
				ClipWait, 0.1
			}
		}
	}
	
	w := Clipboard
	Clipboard := ClipSaved
	return w
}


; increment/decrement selected number ( vim style )
; adapted from https://gist.github.com/Lokno/3ee0253549bc1a730aca
AddSelection( sign , op )
{
	global OP_ADD_LS, OP_EXP, OP_ADD_MS, OP_PW2
	global delay_between_number_changes
	;global trigger
	
	;SendInput {%trigger% Up}
	
	ClipSaved := ClipboardAll
	
	;add_selection_mutex := True

    SendInput ^c
	ClipWait, 0.25
	if ErrorLevel
	{
		Clipboard := ClipSaved
		RETURN
	}
	
    if( RegExMatch( clipboard, "^-?[0-9.]+$" ) ) ; is number
    {
        ; determine smallest increment
        dotPos := InStr( clipboard, "." )
        numLen := StrLen( clipboard )
		is_numLen := numLen   ; length including sign
 
        if( dotPos > 0 )
        {
            exponent := numLen-dotPos
            epsilon := 10**-exponent
            SetFormat, float, 0.%exponent%
        }
        else
        {
            epsilon := 1
        }
 
        num := clipboard
		
		number_sign := 1
		if ( num < 0 )
		{
			numLen := numLen-1
			dotPos := dotPos-1
			number_sign := -1
		}
		
		Switch op
		{
		Case OP_ADD_LS: 
			num := num + sign * epsilon
		
		Case OP_ADD_MS:
		    if ( epsilon = 1 )
			{
				num := num + sign * 10**(numLen-1)
				if ( StrLen( num ) < is_numLen - 1)
				{
					num := num + number_sign * 9 * 10**(numLen-2)
				}
			}
			else
			{
				; do nothing
			}
			
		Case OP_EXP: 

			if (number_sign = -1)
			{
				clipboard:= SubStr(clipboard, 2, numLen)
				num:= clipboard
			}
			
			if (epsilon = 1)
			{
				if (sign > 0)
				{
					num := num . "0"
				}
				else
				{
					num := SubStr(clipboard, 1, numLen-1)
					last_digit := SubStr(clipboard, numLen, 1)
					if ( last_digit != "0")
					{
						num:= num . "." . last_digit 
					}
				}
			}
			else
			{
				if (sign > 0)
				{
					num := SubStr(clipboard, 1, dotPos-1) . SubStr(clipboard, dotPos+1, 1) 
					if (dotPos < numLen-1)
					{
						num := num . "." . SubStr(clipboard, dotPos+2, numLen-(dotPos+1))
					}
					if (dotPos > 1 && SubStr(num, 1,1) = "0")
					{
						; remove zero to the left
						num := SubStr(num, 2 , numLen-1)
					}
				}
				else
				{
					if (dotPos = 1 || RegExMatch( clipboard, "^-?[0]+[.][0-9]+$" ))
					{
						num := SubStr(clipboard, 1, dotPos) . "0" . SubStr(clipboard, dotPos+1, numLen-dotPos)
					}
					else{
						num := SubStr(clipboard, 1, dotPos-2) . "." . SubStr(clipboard, dotPos-1, 1) . SubStr(clipboard, dotPos+1, numLen-dotPos) 
					}
				}
			}
			
			if (number_sign = -1)
			{
				num:= "-" . num
			}

		Default: RETURN
		}
		
        
        clipboard = %num%

        numLen := StrLen( clipboard )

        SendInput ^v
		
        Loop, %numLen%
        {
            SendInput +{Left}
        }  
		SendInput {Shift Up}   ; Seems to get stuck sometimes, idkw
		Sleep delay_between_number_changes
    }
	
	Clipboard := ClipSaved
}

; delete entire line's content 
; 	when ctrl+x is not an available option, 
;	no need to select everything 
ClearLine(){
	Send {End}+{Home 2}{Backspace 2}
}


; move cursor to opening parenthesis or bracket
; if already next to one, move to the next if it exists
; cursor loops all the "items" (goes back to first after the last)
; returns False if failed to execute due to too many chars on the clipboard, True otherwise
GoToOpen(){
	global max_number_of_chars_in_clipboard
	
	ClipSaved := ClipboardAll

	; check if already in position
	; if yes, move to next if it exists
	Clipboard:=
	SendInput +{Left}^c
	ClipWait, 0.1
	
	already_on_one := RegExMatch( Clipboard, "[({\[]" )
	
	SendInput {Right}
	SearchLabel:
	
	if (already_on_one) ; search for next
	{ 	
		Clipboard:=
		SendInput +{End}^c
		ClipWait, 0.1
	}
	else{ ; search from start of the line
		Clipboard:=
		SendInput {End}+{Home}^c
		ClipWait, 0.1
	}
	
	pos := 0
	if(StrLen(Clipboard) <= max_number_of_chars_in_clipboard)
	{
		pos := RegExMatch( Clipboard, "[({\[]" )
	}
	else{
		Clipboard := ClipSaved
		RETURN False
		; prevents going back to SearchLabel,
	}
	
	if (pos > 0)
	{
		; found a position to go to
		SendInput {Left}{Right %pos%}
	}
	else
	{
		; nothing found 
		SendInput {Left}
		
		if(already_on_one){
			; repeat search, now from the start of the line
			already_on_one := False
			Goto, SearchLabel
		}
	}
	
	Clipboard := ClipSaved
	RETURN True
}

;------------------
SelectTillClosed(){
	; 1st check if anything is selected
	; if yes, go to the beggining of the selection
	ClipSaved := ClipboardAll
	
	Clipboard:=
	SendInput ^c
	ClipWait, 0.1
	
	if (StrLen(clipboard)>0){
		SendInput {Left}
	}
	
	; now search for the next symbol
	if(GoToOpen() = False){
		; search exceeds char limit set by max_number_of_chars_in_clipboard
		Clipboard := ClipSaved
		RETURN
	}
	
	; --- select the content within ---
	
	; get symbol before cursor
	Clipboard:=
	SendInput +{Left}^c
	ClipWait, 0.1
	
	char := Clipboard
	
	; reset cursor
	SendInput {Right} 
	
	if (RegExMatch( char, "[({\[]" )){
		; valid character, find its match
		Clipboard:=
		SendInput +{End}^c
		ClipWait, 0.1
		
		rest_of_string := Clipboard
		
		matching_char := 0
		Switch char
		{
		Case "(": matching_char := ")"
		Case "[": matching_char := "]"
		Case "{": matching_char := "}"
		}
		
		lvl:= 1 
		iteration_counter := 0
		iter_limit := 100
		
		; iterate 
		loop Parse, rest_of_string
		{
			;MsgBox,%A_LoopField%
			if (A_LoopField = char){
				lvl:= lvl + 1
			}
			else if (A_LoopField = matching_char){
				lvl:= lvl - 1
			}
			
			if (lvl = 0){
				break
			}
			
			iteration_counter := iteration_counter+1
			if (iteration_counter >= iter_limit){
				iteration_counter := 0
				break
			}
		}
		
		SendInput {Left}+{Right %iteration_counter%}
	}
	
	Clipboard := ClipSaved
}


;------------------
OpenInFullScreen(){
	global apps_to_f11

	hwndtmp:="ahk_id " WinExist("a")
	SendInput {Enter}
	WinWaitNotActive, %hwndtmp%, , 5
	if (errorlevel) {
		RETURN
	}
	SendInput #{Up}
	WinGet, app_name, ProcessName, A
	dot_pos := InStr(app_name, ".")
	app_name := SubStr(app_name, 1, dot_pos-1)
	StringLower, app_name, app_name  ; I prefer to just ignore the casing, but may be a problem for some pair of apps

	if (app_name ~= apps_to_f11){
		SendInput {F11}
	}
}
