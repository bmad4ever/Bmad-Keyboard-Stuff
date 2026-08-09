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
BoostButton   := 2       ; turbo boost button number (1-based)
ToggleButton  := 11      ; toggles between default x1 and slowest x0.4
ReverseX      := 0       ; 1 to flip horizontal
ReverseY      := 0       ; 1 to flip vertical
PollInterval  := 10      ; ms between cursor polls
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
Sensitivity := SensBase * SensTable[SensIndex]

SetTimer, CursorPoll, %PollInterval%

Esc::ExitApp

^Esc::
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
        ToolTip, X=%X% Y=%Y% DX=%DX% DY=%DY% POV=%POV% U=%Uaxis% V=%Vaxis%`ncx=%cx% cy=%cy% nx=%nx% ny=%ny%`nL1=%L1% L2=%L2% Boost=%BT% Sens=%Sensitivity% (x%Mult%)`nBtns=%Btns%
    }
    return
