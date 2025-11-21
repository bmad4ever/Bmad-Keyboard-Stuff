#SingleInstance, Force
SetBatchLines, -1
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen

; Include if available
#include *i WinGetPosEx.ahk 

;=================================================================
;
; USER CONFIGURATION 
;
;=================================================================

; --- PRIMARY CONTROL KEYS ---
; This is the main modifier key. It MUST be held down to activate all Harpoon functions.
trigger := "F24"

; Key used (with the 'trigger' key) to enter the Window Binding Mode (Blue UI).
binder  := "h"

; Key used (with the 'trigger' key) to enter the Window Closing/Kill Mode (Red UI).
killer  := "q" 

; --- COMMAND HOTKEYS (Used with the 'trigger' key) ---
; NOTE: The trigger key itself (F24) is used to Peek/Show the grid.

suspend_key             := "Pause"    ; Toggles script suspension.
clear_key               := "Delete"   ; Removes ALL saved window bindings.
show_all_key            := "u"        ; Restores/activates ALL binded windows.
close_unbound_key       := "CapsLock" ; Tries closing all windows *except* those bound.
force_close_unbound_key := "f22"      ; *Forcefully* closes all windows *except* those bound.
minimize_all_key        := ";"        ; Minimizes all currently binded windows.
close_all_binded_key    := "z"        ; Closes all currently binded windows.
auto_bind_key           := "'"        ; Automatically binds open windows to keys.

; --- MATRIX LAYOUTS CONFIGURATIONS ---

; Layout keys (for positioning windows into screen halves/quarters)
; Format: 3 rows x 3 columns (center is Max/Min)
layout_keys := "
(
y o f i e a x . k
)"

; Harpoon Keys (The Grid) - These are the target keys for binding/closing specific windows.
; Format: 3 rows x 5 columns
harpoon_keys := "
(
v c l p , d s t n r w g m b j
)"

; --- INTERNAL KEY ALIAS ---
trigger_p := trigger " & "    ; DO NOT CHANGE THIS!

;=================================================================
;
;	STARTUP & GENERATORS
;
;=================================================================

KeyMap(trigger " Up", Func("OnTriggerRelease")) 
KeyMap(trigger " & " binder, Func("ReadyToBind")) 
KeyMap(trigger " & " killer, Func("ReadyToClose")) 

; 1. Generate Layout Bindings (Positioning)
layout_list := StrSplit(layout_keys, " ")
for i, k in layout_list{
    if (k = "" || k = "`n" || k = "`r") 
        continue
    iy := Floor((i-1)/3)
    ix := Mod(i-1, 3)
    binding := trigger " & " k
    
    if ( ix != 1 || iy != 1 )
        fn := Func("SendWindowTo").Bind(ix, iy)
    else 
        fn := Func("MaxMinWindow") 
    Hotkey %binding%, % fn
}

; 2. Generate Harpoon Bindings (Window Binding)
harpoon_list := StrSplit(harpoon_keys, " ")
for i, k in harpoon_list{
    if (k = "" || k = "`n" || k = "`r")
        continue
    binding := trigger " & " k
    fn := Func("BindWindow2Key").Bind(k)
    Hotkey %binding%, % fn
}

;=================================================================
;
;	SPECIFIC COMMANDS (MAPPED TO FUNCTION/UTILITY KEYS)
;
;================================================================-

; Maps the 'trigger' key alone (when pressed down) to show the grid.
KeyMap("~"  trigger             , Func("ShowBindingsGrid")) 

; Toggle: Suspends/Unsuspends the entire script. (Uses %suspend_key%)
KeyMap(     trigger_p suspend_key   , Func("ToggleSuspend"))

; Action: Removes all saved window bindings. (Uses %clear_key%)
KeyMap(     trigger_p clear_key  , Func("ClearBindings")) 

; Action: Activates/Restores all currently binded windows. (Uses %show_all_key%)
KeyMap(     trigger_p show_all_key       , Func("ShowAllBindedWindows")) 

; Action: Closes all windows *except* those currently bound. (Uses %close_unbound_key%)
KeyMap(     trigger_p close_unbound_key, Func("CloseNonBindedWindows").Bind(false)) 

; Action: Closes all windows *except* those currently bound (Force). (Uses %force_close_unbound_key%)
KeyMap(     trigger_p force_close_unbound_key, Func("CloseNonBindedWindows").Bind(true)) 

; Action: Minimizes all currently binded windows. (Uses %minimize_all_key%)
KeyMap(     trigger_p minimize_all_key,        Func("MinimizeAllBindedWindows")) 

; Action: Closes all currently binded windows. (Uses %close_all_binded_key%)
KeyMap(     trigger_p close_all_binded_key,    Func("CloseAllBindedWindows"))

; Action: Automatically binds open windows to keys. (Uses %auto_bind_key%)
KeyMap(     trigger_p auto_bind_key,           Func("AutoBind"))

;=================================================================
;
;	CONFIGS (TIMING AND INTERNAL SETTINGS)
;
;================================================================-

tooltip_timeout          := -1200  ; Time OSD messages stay on screen (milliseconds, negative means SetTimer once)
list_update_time_interal := -3500  ; Time the grid stays open in Peek Mode (F24 tap)
list_name_max_len        := 20     ; Max length of window title shown in the grid

apps := {} 
block_list_update := false 
bind_next := false
close_next := false 

icon := ".\trident.ico" 
if FileExist(icon)
    Menu, Tray, Icon, %icon%

trigger_cleanup:=binder:=trigger_p:=fn:=binding:=i:=k:=iy:=ix:=layout_list:=harpoon_list:=""

;=================================================================
;
;	METHODS (LOGIC IMPLEMENTATION)
;
;================================================================-

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
    Gui, GridGUI:Destroy
    OSD() 
    
    color := 0x00ff00
    if a_issuspended
        color := 0x660000 
        
    Gui, SuspendGUI:New
    if FileExist(icon)
        Gui, SuspendGUI:Add, Picture, w64 h64 x32 y32, %icon%
    Gui, SuspendGUI:Color, %color%
    Gui, SuspendGUI:-caption -toolwindow -border +AlwaysOnTop +LastFound +E0x08000000 +ToolWindow +E0x20
    Gui, SuspendGUI:Show, w128 h128 NoActivate
    Sleep 500
    Gui, SuspendGUI:Hide
}

ReadyToBind(){
    global bind_next, close_next, block_list_update
    bind_next := true
    close_next := false 
    OSD("`n  ψ BINDER READY ψ  `n") 
    block_list_update := false 
    ShowBindingsGrid(true) 
    return
}

ReadyToClose(){
    global bind_next, close_next, block_list_update
    close_next := true
    bind_next := false 
    OSD("`n  ψ KILL MODE ψ  `n") 
    block_list_update := false 
    ShowBindingsGrid(true)
    return
}

OSD(msg := "", timeout := 0, target_window_id := 0){
    static OSD_Hwnd
    
    if (msg = "") {
        Gui, OSD_GUI:Destroy
        return
    }

    if (target_window_id != 0)
        WinGetPos, tX, tY, tW, tH, ahk_id %target_window_id%
    else {
        WinGet, win_state, MinMax, A
        WinGetClass, activeClass, A
        
        ; Positioning Fix: Center on screen if active window is minimized or is the Taskbar/Desktop
        if (win_state = -1 || activeClass = "Shell_TrayWnd" || activeClass = "Progman" || activeClass = "WorkerW") { 
             tX := 0, tY := 0
             tW := A_ScreenWidth
             tH := A_ScreenHeight
        } else {
             WinGetPos, tX, tY, tW, tH, A 
        }
    }

    Gui, OSD_GUI:New, +HwndOSD_Hwnd
    Gui, OSD_GUI:+AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20 +E0x08000000
    Gui, OSD_GUI:Color, 1A1A1A 
    Gui, OSD_GUI:Font, s10 cWhite w600, Segoe UI
    Gui, OSD_GUI:Add, Text, Center, %msg%
    Gui, OSD_GUI:Show, Hide AutoSize

    WinGetPos,,, oW, oH, ahk_id %OSD_Hwnd%
    final_X := tX + (tW / 2) - (oW / 2)
    final_Y := tY + (tH / 2) - (oH / 2)

    WinMove, ahk_id %OSD_Hwnd%,, %final_X%, %final_Y%
    Gui, OSD_GUI:Show, NoActivate

    if (timeout != 0) {
        timeout := Abs(timeout)
        SetTimer, CloseOSD, -%timeout%
    }
    return

    CloseOSD:
    Gui, OSD_GUI:Destroy
    return
}

ShowBindingsGrid(keep_open := false){
    global apps, harpoon_keys, block_list_update, list_update_time_interal, list_name_max_len
    global close_next, bind_next
    
    if block_list_update
        return

    Gui, GridGUI:Destroy
    Gui, GridGUI:New, +AlwaysOnTop -Caption +ToolWindow +LastFound +E0x20 +E0x08000000
    Gui, GridGUI:Color, 121212 
    Gui, GridGUI:Font, s9 cWhite, Segoe UI

    cols := 5
    cell_w := 110
    cell_h := 70
    margin := 5
    
    h_keys := StrSplit(harpoon_keys, " ")
    
    Loop % h_keys.MaxIndex() {
        key := h_keys[A_Index]
        if (key = "")
            continue
            
        idx := A_Index - 1
        row := Floor(idx / cols) 
        col := Mod(idx, cols)    
        
        x_pos := margin + (col * (cell_w + margin))
        y_pos := margin + (row * (cell_h + margin))
        
        bound_id := apps[key]
        is_bound := (bound_id && WinExist("ahk_id " bound_id))
        
        if (is_bound) {
            bg_color := close_next ? "592d2d" : "2d4a69"
        } else {
            ; Green tint for available slots in bind mode
            bg_color := bind_next ? "2d4a35" : "2b2b2b"
        }
        
        Gui, GridGUI:Add, Progress, x%x_pos% y%y_pos% w%cell_w% h%cell_h% Background%bg_color% Disabled
        
        StringUpper, key_display, key
        Gui, GridGUI:Font, s14 w700 cWhite
        Gui, GridGUI:Add, Text, x%x_pos% y%y_pos% w%cell_w% h25 +0x200 Center BackgroundTrans, %key_display%
        
        if (is_bound) {
            WinGet, exe_path, ProcessPath, ahk_id %bound_id%
            WinGetTitle, win_title, ahk_id %bound_id%
            
            if StrLen(win_title) > 12
                win_title := SubStr(win_title, 1, 12) "..."
            
            icon_size := 24
            icon_x := x_pos + (cell_w/2) - (icon_size/2)
            icon_y := y_pos + 28 
            
            Gui, GridGUI:Add, Picture, x%icon_x% y%icon_y% w%icon_size% h-1 BackgroundTrans, %exe_path%
            Gui, GridGUI:Font, s8 w400 cSilver
            text_y := y_pos + 52
            Gui, GridGUI:Add, Text, x%x_pos% y%text_y% w%cell_w% h15 +0x200 Center BackgroundTrans, %win_title%
        }
    }

    total_w := (cell_w * cols) + (margin * (cols + 1))
    total_h := (cell_h * 3) + (margin * 4)
    
    WinGet, win_state, MinMax, A
    WinGetClass, activeClass, A
    
    ; Positioning Fix: Center on screen if active window is minimized or is the Taskbar/Desktop
    if (win_state = -1 || activeClass = "Shell_TrayWnd" || activeClass = "Progman" || activeClass = "WorkerW") { 
        tX := 0, tY := 0
        tW := A_ScreenWidth
        tH := A_ScreenHeight
    } else {
        WinGetPos, tX, tY, tW, tH, A
    }

    final_X := tX + (tW / 2) - (total_w / 2)
    final_Y := tY + (tH / 2) - (total_h / 2)
    
    Gui, GridGUI:Show, x%final_X% y%final_Y% w%total_w% h%total_h% NoActivate

    block_list_update := true
    
    ; Only set destruction timer if we are in Peek Mode
    if (keep_open) {
        SetTimer, CLOSE_GRID, Off
    } else {
        SetTimer, CLOSE_GRID, %list_update_time_interal%
    }
    return

    CLOSE_GRID:
    Gui, GridGUI:Destroy
    block_list_update := false
    return
}

OnTriggerRelease(){
    global block_list_update, bind_next, close_next
    bind_next := false
    close_next := false
    block_list_update := false
    OSD() 
    Gui, GridGUI:Destroy
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

MinimizeAllBindedWindows(){
    global apps
    for k, app_id in apps {
        if WinExist("ahk_id " app_id)
            WinMinimize ahk_id %app_id%
    }
}

CloseAllBindedWindows(){
    global apps, tooltip_timeout
    count := 0
    for k, app_id in apps {
        if WinExist("ahk_id " app_id) {
            WinClose ahk_id %app_id%
            count++
        }
    }
    apps := {}
    OSD("`n  ψ CLOSED " count " WINDOWS ψ  `n", tooltip_timeout)
}

ClearBindings(){
    global apps, tooltip_timeout, trigger
    apps := {}
    OSD()
    if GetKeyState(trigger, "P") {
        global block_list_update
        block_list_update := false 
        ShowBindingsGrid(true) 
    } else {
        OSD("`n  ψ ALL CLEARED ψ  `n", tooltip_timeout) 
    }
}

ShowAllBindedWindows(){
    global apps
    for k, app_id in apps
        WinActivate ahk_id %app_id%
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
        if (ObjHasVal(apps, app_id))
            continue
        if (force && RegExMatch(name, "^[Ee]xplorer\.[Ee][Xx][Ee]$") == 0){
            Process, Close, % name
            continue
        }
        WinClose ahk_id %app_id%
    }
}

AutoBind(){
    global apps, tooltip_timeout, block_list_update
    
    ; Define binding order as specified
    bind_order := ["s", "t", "n", "r", "c", "l", "p", ",", "g", "m", "b", "j", "v", "d", "w"]
    
    ; Get all windows
    DetectHiddenWindows, Off
    WinGet, WinList, List
    
    ; Clear existing bindings
    apps := {}
    
    bind_index := 1
    bound_count := 0
    
    Loop, %WinList% {
        if (bind_index > bind_order.MaxIndex())
            break
            
        app_id := WinList%A_Index%
        WinGetTitle, title, ahk_id %app_id%
        
        ; Skip windows without titles
        If (title = "")
            continue
            
        WinGetClass, class, ahk_id %app_id%
        
        ; Skip AHK GUIs and Desktop
        If (class = "AutoHotkeyGUI" || class = "Progman" || class = "WorkerW")
            continue
        
        ; Check if window appears in taskbar
        WinGet, ExStyle, ExStyle, ahk_id %app_id%
        
        ; WS_EX_TOOLWINDOW = 0x80 - if present, window is NOT in taskbar
        hasToolWindow := ExStyle & 0x80
        
        ; Skip tool windows (they don't appear in taskbar)
        If (hasToolWindow)
            continue
        
        ; Check if window is visible
        WinGet, Style, Style, ahk_id %app_id%
        isVisible := Style & 0x10000000  ; WS_VISIBLE
        
        If (!isVisible)
            continue
        
        ; Bind to next key in order
        key := bind_order[bind_index]
        apps[key] := app_id
        bound_count++
        bind_index++
    }
    
    ; Show feedback
    OSD("`n  ψ AUTO-BOUND " bound_count " WINDOWS ψ  `n", tooltip_timeout)
    
    ; Refresh grid
    block_list_update := false
    ShowBindingsGrid(true)
}

SendWindowTo(ix, iy){
    WinGet active_id, ID, A
    SysGet, Mon, MonitorWorkArea
    mon_w := MonRight - MonLeft
    mon_h := MonBottom - MonTop
    
    if (ix = 1)
        target_w := mon_w
    else
        target_w := mon_w / 2
        
    if (iy = 1)
        target_h := mon_h
    else
        target_h := mon_h / 2
        
    if (ix = 2)
        target_x := MonLeft + (mon_w / 2)
    else 
        target_x := MonLeft
        
    if (iy = 2)
        target_y := MonTop + (mon_h / 2)
    else
        target_y := MonTop
    
    WinGet WinState, MinMax, A
    if WinState != 0
        WinRestore A
        
    WinMove, A,, target_x, target_y, target_w, target_h
}

BindWindow2Key(key){
    global apps, bind_next, close_next, tooltip_timeout, block_list_update

    ; --- BIND MODE ---
    if (bind_next){
        bind_next := false
        WinGetTitle title, A
        if (title = ""){
            OSD("`n  ψ NOTHING TO BIND ψ  `n", tooltip_timeout) 
            return
        }
        WinGet wind2bind_id , ID, A
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
        
        OSD(msg, tooltip_timeout, wind2bind_id)
        
        block_list_update := false 
        ShowBindingsGrid(true) 
        return
    }
    
    ; --- KILL MODE ---
    if (close_next){
        close_next := false
        
        if (!apps.HasKey(key)) {
            OSD("`n  ψ NOTHING BOUND TO " key " ψ  `n", tooltip_timeout)
            return 
        }
        
        app2kill := apps[key]
        if (app2kill && WinExist("ahk_id" app2kill)) {
            WinClose ahk_id %app2kill%
            apps.Delete(key)
            
            StringUpper key, key
            OSD("`n  ψ CLOSED [ " key " ] ψ  `n", tooltip_timeout)
            
            block_list_update := false
            ShowBindingsGrid(true)
        }
        return
    }

    ; --- ACTIVATE WINDOW ---
    if (!apps.HasKey(key)) 
        GOTO NOT_BINDED
    app2open := apps[key]
    if (app2open = 0 || !WinExist("ahk_id" app2open) ){ 
        apps.Delete(key)
        GOTO NOT_BINDED
    }
    WinActivate ahk_id %app2open%
    return 
    
    NOT_BINDED:
    StringUpper key, key
    OSD("`n  ψ [ " key " ] : UNBINDED ψ  `n", tooltip_timeout) 
}