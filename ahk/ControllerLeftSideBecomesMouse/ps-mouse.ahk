#NoEnv
#SingleInstance Force
#Persistent
SendMode Input

Menu, Tray, Icon, %A_ScriptDir%\ps-controller.ico

; ============ CONFIG ============
Sensitivity   := 0.08    ; cursor speed multiplier
SensBase      := 0.08    ; default sensitivity
SensTable     := [0.4, 0.7, 1.0, 1.5, 2.7]   ; multipliers: 2 below, default, 2 above
SensIndex     := 3       ; start at default (1.0) - AHK arrays are 1-based
UpButton      := 0       ; D-pad up button number - SET THIS
DownButton    := 0       ; D-pad down button number - SET THIS
BoostMult     := 4       ; speed while boost held
DeadZone      := 10      ; stick-center dead zone (0-50 percent)
SpecStickDead   := 0.25  ; special-state stick center dead zone (higher than cursor DeadZone)
L1Button      := 5       ; left click button number (1-based)
L2Button      := 7       ; right click button number (1-based)
ZoomInButton  := 6       ; zoom in button (Ctrl + WheelUp)
ZoomOutButton := 8       ; zoom out button (Ctrl + WheelDown)
EscButton     := 3       ; escape key (normal); Win+Tab in special state
EnterButton   := 2       ; enter key button number (1-based)
DesktopButton := 13      ; show desktop (Win+D) button number (1-based)
DesktopPrevButton := 9    ; button 9: previous desktop (Alt+F4 in special state)
BoostButton   := 1       ; turbo boost button number (1-based)
ToggleButton  := 14      ; toggles between default x1 and slowest x0.4
SpecialButton := 4       ; hold for special window-management state
DesktopNextButton := 10  ; button 10: next desktop
TabButton     := 12      ; tab key button number (1-based)
ShiftTabButton := 11     ; shift+tab (normal); center window in special state
ReverseX      := 0       ; 1 to flip horizontal
ReverseY      := 0       ; 1 to flip vertical
PollInterval  := 10      ; ms between cursor polls
ScrollSpeed   := 30      ; right-stick wheel notches per second at full deflection
ScrollReverse := 0       ; 1 to invert right-stick scroll direction
RightXOffset  := 16      ; joyGetPosEx offset for right-stick X (16=dwZpos; 20=dwRpos)
RightYOffset  := 20      ; joyGetPosEx offset for right-stick Y (20=dwRpos; 24=dwUpos)
ZoomSpeed     := 40      ; zoom steps per second while a zoom button is held
VolThresh     := 1000    ; trigger dead zone: below this the axis is ignored
VolMaxStep    := 0.6     ; max volume units per poll at full trigger pull (~2s 0-100)
DebugMode     := 0       ; 1 = print live axis + button readout
; ================================

; ---- detect DirectInput joystick via winmm ----
Dev := -1
Loop 16
{
    id := A_Index - 1
    VarSetCapacity(JIP, 52, 0)
    NumPut(52, JIP, 0, "UInt")       ; dwSize
    NumPut(0xFF, JIP, 4, "UInt")     ; dwFlags = JOY_RETURNALL
    if (DllCall("winmm\joyGetPosEx", "UInt", id, "Ptr", &JIP) = 0)
    {
        Dev := id
        break
    }
}
if (Dev = -1)
{
    MsgBox, No DirectInput joystick detected. Connect the controller and put it in gamepad mode (many turbo controllers need TURBO + Start/PS held at power-on). Then restart this script.
    ExitApp
}

LButtonDown := 0
RButtonDown := 0
PrevUp := 0
PrevDown := 0
PrevToggle := 0
ScrollAccum := 0
ShiftHeld := 0
ZoomAccum := 0
PrevNav := 0
PrevEsc := 0
PrevEnter := 0
PrevDesktop := 0
PrevDesktopPrev := 0
PrevDesktopNext := 0
PrevTab := 0
PrevShiftTab := 0
SpecialState := 0
PrevSpecial := 0
PrevSpPov := 65535
PrevSpcPrevDesktop := 0
PrevSpcWinTab := 0
PrevSpcCenter := 0
PrevStickZone := 0
ZoneForSector := [4, 8, 6, 7, 3, 1, 5, 2]
PrevSpcF11 := 0
PrevSpcRoll := 0
RollActive := 0
RollX := 0
RollY := 0
RollW := 0
RollH := 0
VolAcc := 0
PrevSpcExplorer := 0
Sensitivity := SensBase * SensTable[SensIndex]

SetTimer, CursorPoll, %PollInterval%

#InputLevel 1
Esc::ExitApp
#InputLevel 0

^Esc::
    Send, {Shift up}
    ShiftHeld := 0
    Suspend, Toggle
    Pause, Toggle, 1
    return

HideSens:
    ToolTip
    return

CursorPoll:
    ; ---- read raw state ----
    VarSetCapacity(JIP, 52, 0)
    NumPut(52, JIP, 0, "UInt")
    NumPut(0xFF, JIP, 4, "UInt")
    if (DllCall("winmm\joyGetPosEx", "UInt", Dev, "Ptr", &JIP) != 0)
        return

    X := NumGet(JIP, 8, "UInt")      ; dwXpos
    Y := NumGet(JIP, 12, "UInt")     ; dwYpos
    Btn := NumGet(JIP, 32, "UInt")   ; dwButtons bitmask
    POV := NumGet(JIP, 40, "UInt")   ; dwPOV hat switch
    Uaxis := NumGet(JIP, 24, "UInt") ; dwUpos (often D-pad up/down axis)
    Vaxis := NumGet(JIP, 28, "UInt") ; dwVpos (often D-pad left/right axis)
    Zpos := NumGet(JIP, RightYOffset, "UInt") ; right-stick Y axis
    Rpos := NumGet(JIP, RightXOffset, "UInt") ; right-stick X axis

    ; ---- center + dead zone (axis range 0-65535) ----
    Center := 32767.5
    Range  := 32767
    Thresh := DeadZone / 100

    ; ---- button 4: hold to activate special window-management state ----
    SpcP := (Btn & (1 << (SpecialButton - 1))) ? 1 : 0
    SpecialState := SpcP
    if (SpcP and not PrevSpecial)
    {
        PrevSpPov := 65535
        PrevSpcPrevDesktop := 0
        PrevSpcWinTab := 0
        PrevSpcCenter := 0
        PrevStickZone := 0
        PrevSpcF11 := 0
        PrevSpcRoll := 0
        VolAcc := 0
        PrevSpcExplorer := 0
        if ShiftHeld
        {
            ShiftHeld := 0
            Send, {Shift up}
        }
        ToolTip, Special State ON
        SetTimer, HideSens, 1200
    }
    PrevSpecial := SpcP

    ; ---- special state: window management, everything else disabled ----
    if SpecialState
    {
        SpcAF := (Btn & (1 << (DesktopPrevButton - 1))) ? 1 : 0
        if (SpcAF and not PrevSpcPrevDesktop)
            Send, !{F4}
        PrevSpcPrevDesktop := SpcAF

        SpcWT := (Btn & (1 << (EscButton - 1))) ? 1 : 0
        if (SpcWT and not PrevSpcWinTab)
            Send, #{Tab}
        PrevSpcWinTab := SpcWT

        SpcCT := (Btn & (1 << (ShiftTabButton - 1))) ? 1 : 0
        if (SpcCT and not PrevSpcCenter)
            CenterWindow()
        PrevSpcCenter := SpcCT

        ; ---- POV d-pad: monitor move (up/down), Alt+Tab (left/right) ----
        if (POV = 0 or POV = 9000 or POV = 18000 or POV = 27000)
        {
            if (POV != PrevSpPov)
            {
                if (POV = 0)
                    MoveToMonitor(1)
                else if (POV = 18000)
                    MoveToMonitor(-1)
                else if (POV = 27000)
                    Send, !+{Tab}
                else
                    Send, !{Tab}
            }
        }
        PrevSpPov := POV

        ; ---- left stick: window management (cardinals + corners) ----
        ; 8 equal 45-degree sectors around the stick. Fires only when moving
        ; from neutral to a sector, so releasing can't trigger a different action.
        ZX := (X - Center) / Range
        ZY := (Y - Center) / Range

        zone := 0
        if (ZX*ZX + ZY*ZY >= SpecStickDead * SpecStickDead)
        {
            ang := ATan2(ZY, ZX)
            ang := Mod(ang + 382.5, 360)
            idx := Floor(ang / 45)
            zone := ZoneForSector[idx + 1]
        }

        if (zone != 0 and PrevStickZone = 0)
        {
            if (zone = 5)
            {
                WinGet, s, MinMax, A
                if (s = 1)
                    WinRestore, A
                else
                    WinMaximize, A
            }
            else if (zone = 6)
                WinMinimize, A
            else if (zone = 3)
                DockWindow("left")
            else if (zone = 4)
                DockWindow("right")
            else if (zone = 1)
                DockWindow("tl")
            else if (zone = 2)
                DockWindow("tr")
            else if (zone = 7)
                DockWindow("bl")
            else
                DockWindow("br")
        }
        PrevStickZone := zone

        ; ---- L1 (btn 5): F11 borderless fullscreen toggle ----
        SpcF11 := (Btn & (1 << (L1Button - 1))) ? 1 : 0
        if (SpcF11 and not PrevSpcF11)
            Send, {F11}
        PrevSpcF11 := SpcF11

        ; ---- R1 (btn 6): roll-up / roll-down toggle ----
        SpcRoll := (Btn & (1 << (ZoomInButton - 1))) ? 1 : 0
        if (SpcRoll and not PrevSpcRoll)
        {
            if (RollActive)
            {
                WinMove, A, , RollX, RollY, RollW, RollH
                RollActive := 0
            }
            else
            {
                WinGet, rs, MinMax, A
                if (rs != 1)
                {
                    WinGetPos, RollX, RollY, RollW, RollH, A
                    SysGet, CapH, 4
                    SysGet, FrH, 32
                    WinMove, A, , RollX, RollY, RollW, CapH + 2 * FrH
                    RollActive := 1
                }
            }
        }
        PrevSpcRoll := SpcRoll

        ; ---- btn 10: Explorer view toggle (info <-> small icons, via keys) ----
        SpcExp := (Btn & (1 << (DesktopNextButton - 1))) ? 1 : 0
        if (SpcExp and not PrevSpcExplorer)
        {
            WinGetClass, wc, A
            if (wc = "CabinetWClass")
            {
                ahwnd := WinExist("A")
                try
                {
                    shell := ComObjCreate("Shell.Application")
                    for win in shell.Windows
                    {
                        if (win.hwnd = ahwnd)
                        {
                            v := win.Document.CurrentViewMode
                            if (v = 4)
                                Send, ^+2
                            else
                                Send, ^+6
                            ToolTip, Explorer view: %v%
                            SetTimer, HideSens, 1200
                            break
                        }
                    }
                }
            }
        }
        PrevSpcExplorer := SpcExp

        ; ---- L2 (V axis): volume down / R2 (U axis): volume up, speed = pull depth ----
        Vad := (Vaxis > VolThresh) ? (Vaxis - VolThresh) / (65535 - VolThresh) : 0
        Uad := (Uaxis > VolThresh) ? (Uaxis - VolThresh) / (65535 - VolThresh) : 0
        VolAcc += (Uad - Vad) * VolMaxStep
        if (Abs(VolAcc) >= 1)
        {
            vs := Floor(Abs(VolAcc))
            try SoundSet, % (VolAcc > 0 ? "+" : "-") vs
            VolAcc -= (VolAcc > 0 ? vs : -vs)
        }
        return
    }

    ; ---- D-pad up/down adjusts sensitivity ----
    Up := 0
    Down := 0
    if (UpButton and (Btn & (1 << (UpButton - 1))))
        Up := 1
    if (DownButton and (Btn & (1 << (DownButton - 1))))
        Down := 1
    if (POV <= 4500)
        Up := 1
    else if (POV >= 13500 and POV <= 22500)
        Down := 1
    if (Up and not PrevUp)
    {
        SensIndex := Min(5, SensIndex + 1)
        Sensitivity := SensBase * SensTable[SensIndex]
        Mult := SensTable[SensIndex]
        ToolTip, Sensitivity: %Sensitivity% (x%Mult%)
        SetTimer, HideSens, 1200
    }
    if (Down and not PrevDown)
    {
        SensIndex := Max(1, SensIndex - 1)
        Sensitivity := SensBase * SensTable[SensIndex]
        Mult := SensTable[SensIndex]
        ToolTip, Sensitivity: %Sensitivity% (x%Mult%)
        SetTimer, HideSens, 1200
    }
    PrevUp := Up
    PrevDown := Down

    ; ---- POV left/right: browser back/forward ----
    Nav := 0
    if (POV = 27000)
        Nav := -1   ; back
    else if (POV = 9000)
        Nav := 1    ; forward
    if (Nav and not PrevNav)
        Send, % (Nav = -1) ? "!{Left}" : "!{Right}"
    PrevNav := Nav

    ; ---- button 11: toggle default x1 <-> slowest x0.4 ----
    Tgl := (Btn & (1 << (ToggleButton - 1))) ? 1 : 0
    if (Tgl and not PrevToggle)
    {
        if (SensIndex = 1)
            SensIndex := 3
        else if (SensIndex != 3)
            SensIndex := 3
        else
            SensIndex := 1
        Sensitivity := SensBase * SensTable[SensIndex]
        Mult := SensTable[SensIndex]
        ToolTip, Sensitivity: %Sensitivity% (x%Mult%)
        SetTimer, HideSens, 1200
    }
    PrevToggle := Tgl

    ; ---- center + dead zone (axis range 0-65535) ----
    DX := (X - Center) / Range
    DY := (Y - Center) / Range
    if (Abs(DX) < Thresh)
        DX := 0
    if (Abs(DY) < Thresh)
        DY := 0

    DX *= 200 * Sensitivity
    DY *= 200 * Sensitivity

    if (Btn & (1 << (BoostButton - 1)))
    {
        DX *= BoostMult
        DY *= BoostMult
    }
    if (ReverseX)
        DX := -DX
    if (ReverseY)
        DY := -DY

    if (DX != 0 || DY != 0)
    {
        VarSetCapacity(pt, 8)
        DllCall("GetCursorPos", "Ptr", &pt)
        cx := NumGet(pt, 0, "Int")
        cy := NumGet(pt, 4, "Int")
        nx := cx + DX
        ny := cy + DY
        ; relative injection - immune to acceleration, clamps at screen edge by OS
        DllCall("mouse_event", "UInt", 0x0001, "Int", DX, "Int", DY, "UInt", 0, "UPtr", 0)
    }

    ; ---- right stick = scroll wheel ----
    ; vertical by default; hold Shift when deflected mostly sideways for horizontal scroll
    RX := (Rpos - Center) / Range
    RY := (Zpos - Center) / Range
    if (Abs(RX) < Thresh)
        RX := 0
    if (Abs(RY) < Thresh)
        RY := 0
    if ScrollReverse
    {
        RX := -RX
        RY := -RY
    }

    Horiz := (Abs(RX) > Abs(RY))
    RV := Horiz ? RX : RY

    if (RV = 0)
    {
        ScrollAccum := 0
        if ShiftHeld
        {
            ShiftHeld := 0
            Send, {Shift up}
        }
    }
    else
    {
        if Horiz
        {
            if not ShiftHeld
            {
                ShiftHeld := 1
                Send, {Shift down}
            }
        }
        else if ShiftHeld
        {
            ShiftHeld := 0
            Send, {Shift up}
        }
        ScrollAccum += RV * ScrollSpeed * PollInterval / 1000
        while (ScrollAccum >= 1 or ScrollAccum <= -1)
        {
            if (ScrollAccum > 0)
            {
                Send, {WheelDown}
                ScrollAccum -= 1
            }
            else
            {
                Send, {WheelUp}
                ScrollAccum += 1
            }
        }
    }

    ; ---- zoom buttons (Ctrl + scroll wheel) ----
    Zoom := 0
    if (Btn & (1 << (ZoomInButton - 1)))
        Zoom := 1
    else if (Btn & (1 << (ZoomOutButton - 1)))
        Zoom := -1
    else
        ZoomAccum := 0

    if (Zoom != 0)
    {
        ZoomAccum += Zoom * ZoomSpeed * PollInterval / 1000
        while (ZoomAccum >= 1 or ZoomAccum <= -1)
        {
            if (ZoomAccum > 0)
            {
                Send, ^{WheelUp}
                ZoomAccum -= 1
            }
            else
            {
                Send, ^{WheelDown}
                ZoomAccum += 1
            }
        }
    }

    ; ---- escape / enter buttons ----
    EscP := (Btn & (1 << (EscButton - 1))) ? 1 : 0
    if (EscP and not PrevEsc)
        Send, {Esc}
    PrevEsc := EscP

    EntP := (Btn & (1 << (EnterButton - 1))) ? 1 : 0
    if (EntP and not PrevEnter)
        Send, {Enter}
    PrevEnter := EntP

    DskP := (Btn & (1 << (DesktopButton - 1))) ? 1 : 0
    if (DskP and not PrevDesktop)
        Send, #d
    PrevDesktop := DskP

    DPrevP := (Btn & (1 << (DesktopPrevButton - 1))) ? 1 : 0
    if (DPrevP and not PrevDesktopPrev)
        Send, ^#{Left}
    PrevDesktopPrev := DPrevP

    DNextP := (Btn & (1 << (DesktopNextButton - 1))) ? 1 : 0
    if (DNextP and not PrevDesktopNext)
        Send, ^#{Right}
    PrevDesktopNext := DNextP

    TabP := (Btn & (1 << (TabButton - 1))) ? 1 : 0
    if (TabP and not PrevTab)
        Send, {Tab}
    PrevTab := TabP

    STabP := (Btn & (1 << (ShiftTabButton - 1))) ? 1 : 0
    if (STabP and not PrevShiftTab)
        Send, +{Tab}
    PrevShiftTab := STabP

    ; ---- buttons ----
    if (Btn & (1 << (L1Button - 1)))
    {
        if not LButtonDown
        {
            LButtonDown := 1
            Send, {LButton down}
        }
    }
    else if LButtonDown
    {
        LButtonDown := 0
        Send, {LButton up}
    }

    if (Btn & (1 << (L2Button - 1)))
    {
        if not RButtonDown
        {
            RButtonDown := 1
            Send, {RButton down}
        }
    }
    else if RButtonDown
    {
        RButtonDown := 0
        Send, {RButton up}
    }

    ; ---- debug ----
    if DebugMode
    {
        L1 := (Btn & (1 << (L1Button - 1))) ? "1" : "0"
        L2 := (Btn & (1 << (L2Button - 1))) ? "1" : "0"
        BT := (Btn & (1 << (BoostButton - 1))) ? "1" : "0"
        Btns := ""
        Loop 32
        {
            if (Btn & (1 << (A_Index - 1)))
                Btns .= A_Index . " "
        }
        Mult := SensTable[SensIndex]
        ToolTip, X=%X% Y=%Y% DX=%DX% DY=%DY% POV=%POV% U=%Uaxis% V=%Vaxis% RX=%RX% RY=%RY% Shift=%ShiftHeld% Zoom=%Zoom%`ncx=%cx% cy=%cy% nx=%nx% ny=%ny%`nL1=%L1% L2=%L2% Boost=%BT% Sens=%Sensitivity% (x%Mult%)`nBtns=%Btns%
    }
    return

; ---- four-quadrant arctangent, returns degrees in -180..180 ----
ATan2(y, x)
{
    if (x > 0)
        return ATan(y / x) * 57.29577951308232
    else if (x < 0)
        return ATan(y / x) * 57.29577951308232 + (y >= 0 ? 180 : -180)
    else
        return (y > 0 ? 90 : (y < 0 ? -90 : 0))
}

; ---- work area of the monitor containing the active window's center ----
GetMonitorWorkArea(ByRef mL, ByRef mT, ByRef mR, ByRef mB)
{
    WinGetPos, wx, wy, ww, wh, A
    wcx := wx + ww / 2
    wcy := wy + wh / 2
    SysGet, MonCount, MonitorCount
    MonCount := (MonCount > 0) ? MonCount : 0
    MonOK := 0
    Loop %MonCount%
    {
        SysGet, MWA, MonitorWorkArea, %A_Index%
        if (wcx >= MWALeft and wcx <= MWARight and wcy >= MWATop and wcy <= MWABottom)
        {
            MonOK := 1
            break
        }
    }
    if not MonOK
        SysGet, MWA, MonitorWorkArea
    mL := MWALeft
    mT := MWATop
    mR := MWARight
    mB := MWABottom
    return
}

; ---- place active window: left/right half or a corner quarter ----
DockWindow(layout)
{
    GetMonitorWorkArea(mL, mT, mR, mB)
    halfW := (mR - mL) / 2
    halfH := (mB - mT) / 2
    if (layout = "left")
    {
        dX := mL
        dY := mT
        dW := halfW
        dH := mB - mT
    }
    else if (layout = "right")
    {
        dX := mL + halfW
        dY := mT
        dW := halfW
        dH := mB - mT
    }
    else if (layout = "tl")
    {
        dX := mL
        dY := mT
        dW := halfW
        dH := halfH
    }
    else if (layout = "tr")
    {
        dX := mL + halfW
        dY := mT
        dW := halfW
        dH := halfH
    }
    else if (layout = "bl")
    {
        dX := mL
        dY := mT + halfH
        dW := halfW
        dH := halfH
    }
    else
    {
        dX := mL + halfW
        dY := mT + halfH
        dW := halfW
        dH := halfH
    }
    WinGet, ms, MinMax, A
    if (ms = 1)
        WinRestore, A
    WinMove, A, , %dX%, %dY%, %dW%, %dH%
    return
}

; ---- move active window to next/previous monitor, keeping proportional size ----
MoveToMonitor(step)
{
    WinGet, ms, MinMax, A
    if (ms = 1)
        WinRestore, A
    WinGetPos, wx, wy, ww, wh, A
    wcx := wx + ww / 2
    wcy := wy + wh / 2
    SysGet, MonCount, MonitorCount
    MonCount := (MonCount > 0) ? MonCount : 0
    if (MonCount < 2)
        return
    CurIdx := 0
    Loop %MonCount%
    {
        SysGet, MWA, MonitorWorkArea, %A_Index%
        if (wcx >= MWALeft and wcx <= MWARight and wcy >= MWATop and wcy <= MWABottom)
        {
            CurIdx := A_Index
            break
        }
    }
    if (CurIdx = 0)
        return
    TgtIdx := CurIdx + step
    if (TgtIdx < 1)
        TgtIdx := MonCount
    else if (TgtIdx > MonCount)
        TgtIdx := 1
    SysGet, SRC, MonitorWorkArea, %CurIdx%
    SysGet, DST, MonitorWorkArea, %TgtIdx%
    srcW := SRCRight - SRCLeft
    srcH := SRCBottom - SRCTop
    dstW := DSTRight - DSTLeft
    dstH := DSTBottom - DSTTop
    newW := Round(ww * dstW / srcW)
    newH := Round(wh * dstH / srcH)
    if (newW > dstW)
        newW := dstW
    if (newH > dstH)
        newH := dstH
    dX := DSTLeft + (dstW - newW) / 2
    dY := DSTTop + (dstH - newH) / 2
    WinMove, A, , %dX%, %dY%, %newW%, %newH%
    return
}

; ---- restore (if needed) and center active window on its monitor ----
CenterWindow()
{
    WinGet, ms, MinMax, A
    if (ms = 1)
        WinRestore, A
    WinGetPos, wx, wy, ww, wh, A
    GetMonitorWorkArea(mL, mT, mR, mB)
    dstW := mR - mL
    dstH := mB - mT
    if (ww > dstW)
        ww := dstW
    if (wh > dstH)
        wh := dstH
    dX := mL + (dstW - ww) / 2
    dY := mT + (dstH - wh) / 2
    WinMove, A, , %dX%, %dY%, %ww%, %wh%
    return
}
