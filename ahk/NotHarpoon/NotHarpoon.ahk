#SingleInstance, Force ;
#include WinGetPosEx.ahk


;-----------------------------------------------------------------
;	KEY MAPS		KEY MAPS		KEY MAPS		KEY MAPS
;-----------------------------------------------------------------
; TRIGGER KEY! ; which needs to be pressed for any command to occur
trigger := "F24"

; BINDER KEY!  
; this key needs to be tapped while helding trigger key
;  before binding a key to a window
binder:= "h"


trigger_p := trigger " & "   ; do not change this line

; ************************************************************
;  ____
; | ___  keys that set the active window position & dimensions
; ||	   ordered from left to right, top to down, like so:
; ||         ___________
; ||  		|_1_|_2_|_3_|    1,3,7,9: dock at the corner
; ||   		|_4_|_5_|_6_|    4,6: dock at the left/right
; ||    	|_7_|_8_|_9_|    2,8: dock at the top/bottom
;\  /                        5: maximize/minimize window
; \/ 
layout_keys := "
(
y o f i e a x . k
)"


; **************************************************
; list of keys to which the windows can be binded to
; keys must be separated w/ a single space
harpoon_keys := "
(
v c l p , s t n r w g m b j
)"


;******************************************
; mappings for complementary commands
KeyMap("~"  trigger                 , Func("ShowBindingsList"))
KeyMap("~"  trigger_p "Pause"       , Func("ToggleSuspend"))
KeyMap(     trigger_p "Delete"      , Func("ClearBindings")) 
KeyMap(     trigger_p "d"           , Func("ShowAllBindedWindows")) 
KeyMap(     trigger_p "CapsLock"    , Func("CloseNonBindedWindows").Bind(false))   ; "soft" close, may ask permission
KeyMap(     trigger_p "f22"         , Func("CloseNonBindedWindows").Bind(true))    ; "hard" close, will kill the processes


;-----------------------------------------------------------------
;	OTHER CONFIGS		OTHER CONFIGS		OTHER CONFIGS
;-----------------------------------------------------------------

tooltip_timeout:= -1200           ; negative value given in milliseconds
list_update_time_interal:= -5000  ; negative value given in milliseconds
list_name_max_len:= 50			  ; when showing list, clips the names to this number of characters


;-----------------------------------------------------------------
;	STARTUP		STARTUP		STARTUP		STARTUP		STARTUP
;-----------------------------------------------------------------

KeyMap(trigger " Up", Func("OnTriggerRelease"))   ; do not change this
KeyMap(trigger " & " binder, Func("ReadyToBind")) ; do not change this

; - - - - - - - - - - - - - - - - - - - -
layout_keys := StrSplit(layout_keys, " ")
for i, k in layout_keys{
	iy:= Floor((i-1)/3)
	ix:= Mod(i-1, 3)
	binding := trigger " & " k

	fn := 0
	if ( ix != 1 || iy != 1 )
		fn := Func("SendWindowTo").Bind(ix, iy)
	else 
		fn := Func("MaxMinWindow")  ; todo
	Hotkey %binding%, % fn
}


; - - - - - - - - - - - - - - - - - - - - -
harpoon_keys := StrSplit(harpoon_keys, " ")
for i, k in harpoon_keys{
	binding := trigger " & " k
	fn := Func("BindWindow2Key").Bind(k)
	Hotkey %binding%, % fn
}


; - - - - - - - - - - - - - - - - -
apps := {}  ; windows binded to a key
block_list_update := false  ; avoid list update spam
bind_next:= false

; - - - - - - - - - - - - - - - - -
; load icon
icon := ".\trident.ico" 
Menu, Tray, Icon, %icon%


trigger:=binder:=trigger_p:=fn:=binding:=i:=k:=iy:=ix:=layout_keys:=harpoon_keys:=""
;-----------------------------------------------------------------
;	METHODS		METHODS		METHODS		METHODS		METHODS
;-----------------------------------------------------------------

KeyMap( key, func ){
	Hotkey %key%, % func
}

ObjHasVal(obj, val) {
     for k, v in obj
        if (v == val)
        return true
   return false
}


ToggleSuspend(){
	global icon
	
	Suspend, Toggle
	ToolTip
	color := 0x00ff00
	if a_issuspended
		color := 0x660000 
	Gui, New
	Gui, Add, Picture, w64 h64 x32 y32, %icon%
	Gui, Color, %color%
	Gui, -caption -toolwindow -border +AlwaysOnTop +LastFound +E0x08000000 +ToolWindow
	Gui, Show, w128 h128
	
	Sleep 500
	Gui, Hide
}


ReadyToBind(){
	global bind_next
	bind_next:= true
	ShowTooltip( 0, " `n  ψ BINDER READY ψ  `n ", 0)
	return
}


ShowTooltip(window_id, msg, timeout){
	if (window_id != 0)
		WinGetPos,,, Width, Height, ahk_id %window_id%
	else 
		WinGetPos,,, Width, Height, A
	
	ToolTip %msg%, Width/2, Height/2
	
	if timeout != 0
		SetTimer, RemoveToolTip, %timeout%
	return
	
	RemoveToolTip:
	ToolTip
	return
}


MaxMinWindow(){
	WinGet WinState, MinMax, A
	
	if WinState = -1
		WinMaximize A
	else if WinState = 0
		WinMaximize A
	else if WinState = 1
		WinMinimize A
}


ClearBindings(){
	global apps, tooltip_timeout
	apps := {}
	ShowTooltip( 0, " `n  ψ ALL CLEARED ψ  `n " , tooltip_timeout)
}


ShowAllBindedWindows(){
	global apps
	for k, app_id in apps
		WinActivate ahk_id %app_id%
		
	app_id:=k:=""
}


ShowBindingsList(){
	global apps, block_list_update, list_update_time_interal, list_name_max_len
	
	if block_list_update
		return
	
	
	;MsgBox "hey!"
	
	msg:= ""
	for key, app_id in apps{
		if not WinExist("ahk_id " app_id){
			apps.Delete(key)
			continue
		}

		WinGetTitle title, ahk_id %app_id%
		
		StringUpper key, key
		if StrLen(title)>list_name_max_len
			title:= "..." SubStr(title, -list_name_max_len)
		msg.= " [ " key " ] : " title " `n"
	}
	
	if StrLen(msg) = 0 
		ShowTooltip( 0, "ψ`n  NO BINDINGS  `nψ", 0)
	else		
		ShowTooltip( 0, "ψ`n" msg "ψ", 0)
	
	
	block_list_update := true
	SetTimer, RE_UPDATE, %list_update_time_interal%
	msg:=""
	return 
	
	RE_UPDATE:
	block_list_update := false
	return
}


OnTriggerRelease(){
	global block_list_update, bind_next
	
	bind_next:= false
	block_list_update := false
	ToolTip
}


CloseNonBindedWindows(force){
	global apps

	DetectHiddenWindows, Off
	WinGet,WinList,List
	loop, %WinList% {
		app_id := WinList%A_Index%
		
		WinGetTitle title, ahk_id %app_id%
		If (title = "")
			continue
			
		WinGetClass class, ahk_id %app_id%	
		If (class = "AutoHotkeyGUI" || class = "Progman")
			continue
			
		WinGet, name, ProcessName, ahk_id %app_id%
		
		; debug ; print:= pid ":" name ":" title ":" class
		; debug ; MsgBox %print%

		if (ObjHasVal(apps, app_id))
			continue
		
		; so, according to documentation, need to use AND to shortcircuit. && may bot shortcircuit.
		if (force && RegExMatch(name, "^[Ee]xplorer\.[Ee][Xx][Ee]$") == 0){
			Process, Close, % name
			continue
		}
		; else
		WinClose ahk_id %app_id%
	}
	
	app_id:=k:=v:=name:=title:=class:=""
}


SendWindowTo(ix, iy){
; 1,1 is the middle, and should never be passed to this method
	global sleep_till_next_move
	
	WinGet active_id, ID, A
	WinGetPos, tray_x, tray_y, tray_w, tray_h, ahk_class Shell_TrayWnd

	; I don't quite get what's going on w/ the window coordinates & dimensions
	;this is likely not correct, but somehow works
	
	SysGet, total_width_v, 59  ;78  ;16  ;61  ;59 
	SysGet, total_height_v, 60  ;79  ;17  ;62  ;60
	total_width := A_ScreenWidth
	total_height := A_ScreenHeight

	WinGetPosEx(active_id,X,Y,Width,Height,Offset_X,Offset_Y)

	xx := [ 0, 0, total_width/2 ]
	yy := [ 0, 0, total_height/2]
	wx := [ total_width_v/2, total_width_v, total_width_v/2]
	hy := [ total_height_v/2, (total_height+total_height_v)/2, total_height_v/2]  ; what???
	target_w := Ceil(wx[ix+1] - Offset_X/2)
	target_h := hy[iy+1]
	
	if (tray_h > tray_w){
		target_w := Ceil(target_w - tray_w/2)
		if (tray_x < 20){ 
			;tray_w*total_width_v/total_width/2 + total_width/2
			xx := [ tray_w, tray_w, Floor(tray_w*total_width_v/total_width/2 + total_width/2)]
		}
		else{
			xx[3] -= tray_w*total_width_v/total_width/2
			xx[3] := Floor(xx[3])
		}
	}
	else {		
		target_h := Ceil(target_h - tray_h/2)
		
		if (tray_y < 20){ 
			yy := [ tray_h, tray_h, Floor(tray_h*total_height_v/total_height/2 + total_height/2)]
		}
		else{
			yy[3] -= tray_h*total_height_v/total_height/2
			yy[3] := Floor(yy[3])
		}		
	}
	
	target_x := xx[ix+1] + Offset_X
	target_y := yy[iy+1]  ; + Offset_Y 	
		
	; Restore seems to add some delay, so I check the state 1st and only call it if rly needed
	WinGet WinState, MinMax, A
	if WinState != 0
		WinRestore A
		
	WinMove, A,, target_x, target_y, target_w, target_h
}


BindWindow2Key(key){
	global apps, bind_next, tooltip_timeout

	; map the current active window to the pressed key
	if (bind_next){
		bind_next:= false
		
		; avoid binding explorer
		WinGetTitle title, A
		if (title = ""){
			ShowTooltip( 0, " `n  ψ NOTHING TO BIND ψ  `n ", tooltip_timeout )
			return
		}
		
		WinGet wind2bind_id , ID, A
		
		; if already binded, remove prev. bind
		for k, app_id in apps
			if (app_id = wind2bind_id){
				apps.Delete(k)
				break
			}
		
		
		apps[key] := wind2bind_id 
		
		WinGet name, ProcessName, A
		StringUpper key, key
		msg := "BINDED TO " key
		msg := "`n  ψ " name " ψ  `n`n  " StrReplace(Format("{:0" Max(0, Floor((StrLen(name)-StrLen(msg))/2)) "}",0),0," ") msg "`n "
		ShowTooltip( wind2bind_id, msg, tooltip_timeout )

		msg:=name:=""
		return
	}
	
	; else, if shift not pressed 
	; check if there is any window mapped to the pressed key
	CHECK_BINDED:
	if (!apps.HasKey(key)) 
		GOTO NOT_BINDED
		
	app2open := apps[key]
	
	if (app2open = 0 || !WinExist("ahk_id" app2open) ){ 
		apps.Delete(key)
		GOTO NOT_BINDED
	}
	
	; ACTIVATE BINDED WINDOW:
	WinActivate ahk_id %app2open%
	; setting as active should unminimize it, so no need to check/change state
	return 
	
	NOT_BINDED:
	StringUpper key, key
	ShowTooltip( 0, " `n  ψ [ " key " ] : UNBINDED ψ  `n ", tooltip_timeout )
}
