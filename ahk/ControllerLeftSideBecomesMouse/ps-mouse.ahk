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
DeadZone      := 10      ; stick-center dead zone (0-50 percent)
SpecStickDead   := 0.25  ; special-state stick center dead zone (higher than cursor DeadZone)
RepeatMinSpeed  := 1     ; state-2 arrow auto-repeat per second at dead-zone edge
RepeatMaxSpeed  := 50    ; state-2 arrow auto-repeat per second at full deflection
L1Button      := 5       ; left click button number (1-based)
L2Button      := 7       ; right click button number (1-based)
ZoomInButton  := 6       ; zoom in button (Ctrl + WheelUp)
ZoomOutButton := 8       ; zoom out button (Ctrl + WheelDown)
EscButton     := 3       ; escape key (normal); Win+Tab in special state
EnterButton   := 2       ; enter key button number (1-based)
DesktopButton := 13      ; show desktop (Win+D) button number (1-based)
DesktopPrevButton := 9    ; button 9: previous desktop (Alt+F4 in special state)
CtrlButton    := 1       ; Ctrl hold button number (1-based)
Special2Button := 14     ; hold for special state 2 (clipboard actions)
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
ScrollAccum := 0
ShiftHeld := 0
CtrlHeld := 0
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
Special2State := 0
PrevSpecial2 := 0
Prev2C := 0
Prev2X := 0
Prev2Del := 0
Prev2V := 0
Prev2Z := 0
Prev2ZR := 0
Prev2Y := 0
Prev2Stick := 0
Prev2Ctrl := 0
Prev2Space := 0
Prev2AltGr := 0
PrevSpPov := 65535
PrevSpcPrevDesktop := 0
PrevSpcWinTab := 0
PrevSpcCenter := 0
PrevStickZone := 0
ZoneForSector := [4, 8, 6, 7, 3, 1, 5, 2]
ArrowTable := ["Right", "Right Up", "Up", "Up Left", "Left", "Left Down", "Down", "Down Right"]
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


; Optional Suspend Shortcut
;^Esc::
;    Send, {Shift up}
;    ShiftHeld := 0
;    Suspend, Toggle
;    Pause, Toggle, 1
;    return

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

    ; ---- button 14: hold to activate special state 2 ----
    Sp2P := (Btn & (1 << (Special2Button - 1))) ? 1 : 0
    Special2State := Sp2P
    if (Sp2P and not PrevSpecial2)
    {
        Prev2C := 0
        Prev2X := 0
        Prev2Del := 0
        Prev2V := 0
        Prev2Z := 0
        Prev2ZR := 0
        Prev2Y := 0
        Prev2Ctrl := 0
        Prev2Space := 0
        Prev2AltGr := 0
        Prev2Stick := 0
        RepeatAcc2 := 0
        Prev2PovD := 0
        if ShiftHeld
        {
            ShiftHeld := 0
            Send, {Shift up}
        }
        if CtrlHeld
        {
            CtrlHeld := 0
            Send, {Ctrl up}
        }
        ToolTip, Special State 2 ON
        SetTimer, HideSens, 1200
    }
    PrevSpecial2 := Sp2P

    ; ---- release held keys when leaving state 2 ----
    if (Sp2P = 0 and (Prev2Stick != 0 or Prev2Ctrl or Prev2Space or Prev2AltGr))
    {
        if (Prev2Stick != 0)
        {
            Sp2Arrows := ArrowTable[Prev2Stick]
            Loop, Parse, Sp2Arrows, %A_Space%
                Send, {%A_LoopField% up}
            Prev2Stick := 0
            RepeatAcc2 := 0
        }
        if Prev2Ctrl
        {
            Send, {Ctrl up}
            Prev2Ctrl := 0
        }
        if Prev2Space
        {
            Send, {Space up}
            Prev2Space := 0
        }
        if Prev2AltGr
        {
            Send, {RAlt up}
            Prev2AltGr := 0
        }
    }

    ; ---- special state 2: clipboard actions, normal functions disabled ----
    if Special2State
    {
        Sp2C := (Btn & (1 << (CtrlButton - 1))) ? 1 : 0
        if (Sp2C and not Prev2C)
            Send, ^c
        Prev2C := Sp2C

        Sp2X := (Btn & (1 << (EnterButton - 1))) ? 1 : 0
        if (Sp2X and not Prev2X)
            Send, ^x
        Prev2X := Sp2X

        Sp2Del := (Btn & (1 << (EscButton - 1))) ? 1 : 0
        if (Sp2Del and not Prev2Del)
            Send, {Delete}
        Prev2Del := Sp2Del

        Sp2V := (Btn & (1 << (SpecialButton - 1))) ? 1 : 0
        if (Sp2V and not Prev2V)
            Send, ^v
        Prev2V := Sp2V

        Sp2Z := (Btn & (1 << (L2Button - 1))) ? 1 : 0
        if (Sp2Z and not Prev2Z)
            Send, ^z
        Prev2Z := Sp2Z

        Sp2ZR := (Btn & (1 << (ZoomOutButton - 1))) ? 1 : 0
        if (Sp2ZR and not Prev2ZR)
            Send, ^+z
        Prev2ZR := Sp2ZR

        Sp2Y := (Btn & (1 << (ZoomInButton - 1))) ? 1 : 0
        if (Sp2Y and not Prev2Y)
            Send, ^y
        Prev2Y := Sp2Y

        ; ---- button 5: Ctrl hold / button 12: Space hold ----
        if (Btn & (1 << (L1Button - 1)))
        {
            if not Prev2Ctrl
                Send, {Ctrl down}
            Prev2Ctrl := 1
        }
        else if Prev2Ctrl
        {
            Send, {Ctrl up}
            Prev2Ctrl := 0
        }

        ; ---- button 11/12: Space hold ----
        if ((Btn & (1 << (TabButton - 1))) or (Btn & (1 << (ShiftTabButton - 1))))
        {
            if not Prev2Space
                Send, {Space down}
            Prev2Space := 1
        }
        else if Prev2Space
        {
            Send, {Space up}
            Prev2Space := 0
        }

        ; ---- button 10: AltGr (RAlt) hold ----
        if (Btn & (1 << (DesktopNextButton - 1)))
        {
            if not Prev2AltGr
            {
                Send, {RAlt down}
                Prev2AltGr := 1
            }
        }
        else if Prev2AltGr
        {
            Send, {RAlt up}
            Prev2AltGr := 0
        }

        ; ---- d-pad down: Alt+Enter ----
        PovD2 := (POV = 18000) ? 1 : 0
        if (PovD2 and not Prev2PovD)
            Send, !{Enter}
        Prev2PovD := PovD2

        ; ---- sticks: arrows (8 cardinals, diagonals = 2 keys), left mirrors right ----
        R2X := (Rpos - Center) / Range
        R2Y := -(Zpos - Center) / Range
        L2X := (X - Center) / Range
        L2Y := -(Y - Center) / Range
        zone := 0
        Mag2 := 0
        if (L2X*L2X + L2Y*L2Y >= SpecStickDead * SpecStickDead)
        {
            ang := ATan2(L2Y, L2X)
            ang := Mod(ang + 382.5, 360)
            zone := Floor(ang / 45) + 1
            Mag2 := Sqrt(L2X*L2X + L2Y*L2Y)
        }
        if (zone = 0 and R2X*R2X + R2Y*R2Y >= SpecStickDead * SpecStickDead)
        {
            ang := ATan2(R2Y, R2X)
            ang := Mod(ang + 382.5, 360)
            zone := Floor(ang / 45) + 1
            Mag2 := Sqrt(R2X*R2X + R2Y*R2Y)
        }
        if (zone != Prev2Stick)
        {
            if (Prev2Stick != 0)
            {
                Sp2Arrows := ArrowTable[Prev2Stick]
                Loop, Parse, Sp2Arrows, %A_Space%
                    Send, {%A_LoopField% up}
            }
            if (zone != 0)
            {
                Sp2Arrows := ArrowTable[zone]
                Loop, Parse, Sp2Arrows, %A_Space%
                    Send, {%A_LoopField% down}
            }
            Prev2Stick := zone
            RepeatAcc2 := 0
        }
        else if (zone != 0)
        {
            Mag2 := Min(Mag2, 1)
            Mag2 := Max(Mag2, SpecStickDead)
            Norm := (Mag2 - SpecStickDead) / (1 - SpecStickDead)
            CurSpd := RepeatMinSpeed + Norm * (RepeatMaxSpeed - RepeatMinSpeed)
            RepeatAcc2 += PollInterval
            while (RepeatAcc2 >= 1000 / CurSpd)
            {
                RepeatAcc2 -= 1000 / CurSpd
                Sp2Arrows := ArrowTable[zone]
                Loop, Parse, Sp2Arrows, %A_Space%
                    Send, {%A_LoopField% down}
            }
        }
        return
    }

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
        if CtrlHeld
        {
            CtrlHeld := 0
            Send, {Ctrl up}
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

    ; ---- center + dead zone (axis range 0-65535) ----
    DX := (X - Center) / Range
    DY := (Y - Center) / Range
    if (Abs(DX) < Thresh)
        DX := 0
    if (Abs(DY) < Thresh)
        DY := 0

    DX *= 200 * Sensitivity
    DY *= 200 * Sensitivity

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

    ; ---- button 1: Ctrl hold ----
    if (Btn & (1 << (CtrlButton - 1)))
    {
        if not CtrlHeld
        {
            CtrlHeld := 1
            Send, {Ctrl down}
        }
    }
    else if CtrlHeld
    {
        CtrlHeld := 0
        Send, {Ctrl up}
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
        CT := (Btn & (1 << (CtrlButton - 1))) ? "1" : "0"
        Btns := ""
        Loop 32
        {
            if (Btn & (1 << (A_Index - 1)))
                Btns .= A_Index . " "
        }
        Mult := SensTable[SensIndex]
        ToolTip, X=%X% Y=%Y% DX=%DX% DY=%DY% POV=%POV% U=%Uaxis% V=%Vaxis% RX=%RX% RY=%RY% Shift=%ShiftHeld% Zoom=%Zoom%`ncx=%cx% cy=%cy% nx=%nx% ny=%ny%`nL1=%L1% L2=%L2% Ctrl=%CT% Sens=%Sensitivity% (x%Mult%)`nBtns=%Btns%
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
