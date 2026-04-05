; ##############################################################################
; ####################### OnTheFlyOllama Configuration ########################
; ##############################################################################

; Define your trigger key here (standard AHK hotkey format)
TriggerKey := "Pause & Space"

; Define the Ollama model to run
OllamaModel := "seeker"

; Command Timeout in seconds
OllamaTimeout := 50

; GUI Appearance Colors (RGB hex format)
BgColor := "1E1E1E"        ; Dark grey background
TextColor := "FFFFFF"      ; White text
EditBgColor := "2D2D2D"    ; Slightly lighter background for the text box
PromptColor := "AAAAAA"    ; Grey color for the original prompt history
CmdColor := "FFD700"       ; Gold/Yellow for the CMD command history

; Tray Icon
TrayIconFile := "shell32.dll"
TrayIconIndex := 3 ; Command Prompt icon

; ##############################################################################
; ############################ Script Execution ###############################
; ##############################################################################

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

if (TrayIconFile != "")
    Menu, Tray, Icon, %TrayIconFile%, %TrayIconIndex%

; Global state
IsGuiVisible := false
ResultReceived := false
Phase2Received := false
IsProcessing := false
IsFinished := false
OriginalPrompt := ""
CurrentFolderPath := ""

Hotkey, %TriggerKey%, OpenGui


return

; --- GUI Definition ---

OpenGui:
    if (IsGuiVisible)
        return

    ; Attempt to detect active Explorer path
    CurrentFolderPath := GetActiveExplorerPath()
    
    ; Display text for the path label
    PathLabelText := (CurrentFolderPath == "") ? "[Default Environment]" : CurrentFolderPath

    IsGuiVisible := true
    ResultReceived := false
    Phase2Received := false
    IsProcessing := false
	IsFinished := false
    OriginalPrompt := ""

    ; Fixed dimensions
    GuiWidth := 620
    GuiHeight := 450 

    Gui, New, +AlwaysOnTop -Caption +Border +HwndMyGuiHwnd
    Gui, Color, %BgColor%, %EditBgColor%
    Gui, Font, s11 c%TextColor%, Segoe UI

    ; Path Display (Top Left)
    Gui, Font, s8 Bold c%PromptColor%
    Gui, Add, Text, vPathDisplay x10 y5 w490 +Left, PATH: %PathLabelText%

    ; Status Indicator (Top Right)
    Gui, Font, s9 Bold c%PromptColor%
    Gui, Add, Text, vStatus x510 y5 w100 +Right, [OLLAMA]
    
    ; Phase 1 History (Ollama Prompt) - Reserved space at top
    Gui, Font, s11 c%PromptColor%
    Gui, Add, Text, vPromptHistory x10 y35 w600 h50 +Wrap
    
    ; Phase 2 History (CMD Command) - Reserved space
    Gui, Font, s11 c%CmdColor%
    Gui, Add, Text, vCmdHistory x10 y90 w600 h50 +Wrap
    
    ; Text Box - Fixed position at the bottom half
    Gui, Font, s12 c%TextColor%
    Gui, Add, Edit, vUserInput x10 y150 w600 h290 -VScroll +Multi -WantReturn, 
    
    ; Hidden button to handle Enter key
    Gui, Add, Button, w0 h0 Default gSubmitInput, Submit

    ; Show the GUI with fixed size
    Gui, Show, w%GuiWidth% h%GuiHeight% Center, OnTheFlyOllama
    GuiControl, Focus, UserInput
return

SubmitInput:
    if (IsFinished) {
        Gosub, CloseGui
        return
    }
		
    if (IsProcessing)
        return

    if (Phase2Received) {
        Gosub, CloseGui
        return
    }

    Gui, Submit, NoHide
    if (Trim(UserInput) = "")
        return

    IsProcessing := true

    if (!ResultReceived) {
        ; --- Phase 1: Ollama ---
        OriginalPrompt := UserInput
        GuiControl, Disable, UserInput
        GuiControl,, UserInput, Calling Ollama (%OllamaModel%)... Please wait...
        
        Result := RunExternalCommand(OllamaModel, OriginalPrompt, OllamaTimeout, true, CurrentFolderPath)
        Result := Trim(Result, " `t`r`n")
        
        ; Remove code indicators ``` only if they wrap the entire message
        if (SubStr(Result, 1, 3) = "``````" && SubStr(Result, -2) = "``````") {
            Result := SubStr(Result, 4, StrLen(Result) - 6)
            Result := Trim(Result, " `t`r`n")
        }
        
        GuiControl,, PromptHistory, %OriginalPrompt%
        GuiControl, Enable, UserInput
        GuiControl,, UserInput, %Result%
        GuiControl, Focus, UserInput
        
        GuiControl,, Status, [POWERSHELL]
        SendMessage, 0x00B1, 0, -1, Edit1, ahk_id %MyGuiHwnd%
        
        ResultReceived := true
        IsProcessing := false
        Sleep, 300
        SetTimer, CloseWatcher, 50
    } else {
        ; --- Phase 2: Direct PowerShell ---
        CmdToRun := UserInput
        GuiControl, Disable, UserInput
        GuiControl,, UserInput, Executing PowerShell command... Please wait...
        
        Result := RunExternalCommand("", CmdToRun, OllamaTimeout, false, CurrentFolderPath)
        Result := Trim(Result, " `t`r`n")
        
        ; IMPORTANT: Transition state regardless of success/error
		Phase2Received := true
		IsFinished := true   
		IsProcessing := false
        
        GuiControl,, CmdHistory, %CmdToRun%
        GuiControl,, Status, [FINISHED]
        
        ; Lock the box and display result
        GuiControl, +ReadOnly, UserInput
        GuiControl, Enable, UserInput
        GuiControl,, UserInput, %Result%
        GuiControl, Focus, UserInput
        
        SendMessage, 0x00B1, 0, -1, Edit1, ahk_id %MyGuiHwnd%
    }
return

; --- Helper Functions ---

RunExternalCommand(model, prompt, timeoutSeconds, isOllama, workingDir) {
    tempPromptFile := A_ScriptDir . "\_input.txt"
    tempOutputFile := A_ScriptDir . "\_output.txt"
    tempPsFile     := A_ScriptDir . "\_run.ps1"
    
    FileDelete, %tempPromptFile%
    FileDelete, %tempOutputFile%
    FileDelete, %tempPsFile%
        
    try {
        f := FileOpen(tempPromptFile, "w", "UTF-8-RAW")
        f.Write(prompt)
        f.Close()
    } catch {
        return "Error: Could not write input file."
    }
    
    if (isOllama) {
        ; Use PowerShell to pipe the content correctly to Ollama
        psCmd := "Get-Content -Path '" . tempPromptFile . "' -Raw | ollama run " . model
    } else {
        ; For direct execution, run the prompt string as a command
        psCmd := prompt
    }

    ; Create a PowerShell script with Set-Location for the detected path
    if (isOllama) {
        psScript = 
        (LTrim
        $OutputEncoding = [System.Text.Encoding]::UTF8
        try {
            Set-Location -Path "%workingDir%" -ErrorAction SilentlyContinue
            %psCmd% | Out-File -FilePath "%tempOutputFile%" -Encoding utf8 -ErrorAction SilentlyContinue
        } catch {
            "Error executing command: $($_.Exception.Message)" | Out-File -FilePath "%tempOutputFile%" -Encoding utf8
        }
        )
    } else {
        psScript = 
        (LTrim
        $OutputEncoding = [System.Text.Encoding]::UTF8
        `$ErrorActionPreference = "Continue"
        try {
            Set-Location -Path "%workingDir%" -ErrorAction SilentlyContinue
            # Capture all streams (*>) for PowerShell phase
            & { %psCmd% } *>&1 | Out-File -FilePath "%tempOutputFile%" -Encoding utf8
        } catch {
            "System Error: $($_.Exception.Message)" | Out-File -FilePath "%tempOutputFile%" -Encoding utf8
        }
        )
    }
    FileAppend, %psScript%, %tempPsFile%, UTF-8-RAW
    
    try {
        ; Run PowerShell hidden
        Run, powershell -ExecutionPolicy Bypass -File "%tempPsFile%", %A_ScriptDir%, Hide, targetPid
        
        startTime := A_TickCount
        timeoutMs := timeoutSeconds * 1000
        
        Loop {
            if (A_TickCount - startTime > timeoutMs) {
                Process, Close, %targetPid%
                if (isOllama)
                    Run, taskkill /F /IM ollama.exe,, Hide
                return "Error: Command timed out after " . timeoutSeconds . " seconds."
            }
            Process, Exist, %targetPid%
            if (!ErrorLevel) {
                Sleep, 1000
                break
            }
            Sleep, 500
        }
        
        if FileExist(tempOutputFile) {
            FileRead, output, *P65001 %tempOutputFile%
        }
        
        if (Trim(output) == "") {
            if (isOllama)
                return "Error: No output received from PowerShell. Verify the command works manually."
            else
                return "Command executed successfully (no output)."
        }
        
        ; Aggressive Cleaning (removes terminal artifacts)
        Loop, 31 {
            if (A_Index = 10 || A_Index = 13)
                continue
            output := StrReplace(output, Chr(A_Index), "")
        }
        output := RegExReplace(output, "\[\?[0-9;]*[a-zA-Z]")
        output := RegExReplace(output, "\[[0-9;]*[a-zA-Z]")
        output := StrReplace(output, "`r`n", "[[NEWLINE]]")
        output := StrReplace(output, "`r", "")
        output := StrReplace(output, "[[NEWLINE]]", "`r`n")
        
        FileDelete, %tempPromptFile%
        FileDelete, %tempOutputFile%
        FileDelete, %tempPsFile%
        
        return Trim(output)
    } catch e {
        return "System Error: Failed to initiate PowerShell command."
    }
}

GetActiveExplorerPath() {
    ; Get the HWND of the active window
    activeHwnd := WinActive("A")
    if !activeHwnd
        return ""

    ; Check if the active window is File Explorer (CabinetWClass or ExploreWClass)
    WinGetClass, activeClass, ahk_id %activeHwnd%
    if !(activeClass ~= "CabinetWClass|ExploreWClass")
        return ""

    ; Use COM to find the path of the active window
    try {
        for window in ComObjCreate("Shell.Application").Windows {
            if (window.hwnd == activeHwnd) {
                path := window.Document.Folder.Self.Path
                return path
            }
        }
    }
    return ""
}

; --- Post-Result Input Handling ---

CloseWatcher:
    if (!IsGuiVisible || !ResultReceived) {
        SetTimer, CloseWatcher, Off
        return
    }

    if (A_TimeIdlePhysical < 50) {
        isCtrl := GetKeyState("Ctrl", "P")
        isC := GetKeyState("c", "P")
        if (isCtrl || isC)
            return
            
        ; If we have not finished Phase 2, don't close on any key
        ; This allows the user to edit the text box.
        if (!Phase2Received) {
            return
        }

        ; After Phase 2, any key press closes the window
        Gosub, CloseGui
    }
return

CloseGui:
    SetTimer, CloseWatcher, Off
    Gui, Destroy
    IsGuiVisible := false
return

GuiEscape:
GuiClose:
    Gosub, CloseGui
return
