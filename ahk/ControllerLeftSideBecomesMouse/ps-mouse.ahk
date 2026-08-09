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
L1Button      := 5       ; left click button number (1-based)
L2Button      := 7       ; right click button number (1-based)
ZoomInButton  := 6       ; zoom in button (Ctrl + WheelUp)
ZoomOutButton := 8       ; zoom out button (Ctrl + WheelDown)
EscButton     := 3       ; escape key button number (1-based)
EnterButton   := 2       ; enter key button number (1-based)
DesktopButton := 13      ; show desktop (Win+D) button number (1-based)
CloseButton   := 9       ; close window (Alt+F4) button number (1-based)
BoostButton   := 1       ; turbo boost button number (1-based)
ToggleButton  := 14      ; toggles between default x1 and slowest x0.4
MaximizeButton := 4      ; maximize window (Win+Up) button number (1-based)
WinTabButton  := 10      ; windows+tab (task view) button number (1-based)
TabButton     := 12      ; tab key button number (1-based)
ShiftTabButton := 11     ; shift+tab button number (1-based)
ReverseX      := 0       ; 1 to flip horizontal
ReverseY      := 0       ; 1 to flip vertical
PollInterval  := 10      ; ms between cursor polls
ScrollSpeed   := 30      ; right-stick wheel notches per second at full deflection
ScrollReverse := 0       ; 1 to invert right-stick scroll direction
RightXOffset  := 16      ; joyGetPosEx offset for right-stick X (16=dwZpos; 20=dwRpos)
RightYOffset  := 20      ; joyGetPosEx offset for right-stick Y (20=dwRpos; 24=dwUpos)
ZoomSpeed     := 40      ; zoom steps per second while a zoom button is held
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
PrevClose := 0
PrevTab := 0
PrevShiftTab := 0
PrevWinTab := 0
PrevMaximize := 0
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
    Center := 32767.5
    Range  := 32767
    Thresh := DeadZone / 100

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

    ClsP := (Btn & (1 << (CloseButton - 1))) ? 1 : 0
    if (ClsP and not PrevClose)
        Send, !{F4}
    PrevClose := ClsP

    TabP := (Btn & (1 << (TabButton - 1))) ? 1 : 0
    if (TabP and not PrevTab)
        Send, {Tab}
    PrevTab := TabP

    STabP := (Btn & (1 << (ShiftTabButton - 1))) ? 1 : 0
    if (STabP and not PrevShiftTab)
        Send, +{Tab}
    PrevShiftTab := STabP

    WTabP := (Btn & (1 << (WinTabButton - 1))) ? 1 : 0
    if (WTabP and not PrevWinTab)
        Send, #{Tab}
    PrevWinTab := WTabP

    MaxP := (Btn & (1 << (MaximizeButton - 1))) ? 1 : 0
    if (MaxP and not PrevMaximize)
    {
        WinGet, MaxState, MinMax, A
        if (MaxState = 1)
            WinMinimize, A
        else
            WinMaximize, A
    }
    PrevMaximize := MaxP

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
