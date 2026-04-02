#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════╗
; ║                     USER CONFIGURATION                      ║
; ║  Edit the path below to point to your desired backup folder. ║
; ║  Use a full absolute path. Examples:                         ║
; ║    BackupFolder := "C:\Users\YourName\Backup"               ║
; ║    BackupFolder := "D:\MyBackups"                           ║
; ╚══════════════════════════════════════════════════════════════╝

BackupFolder := "A:\DIRTY_BACKUPS"

; Shared state for the fade overlay (used by FlashOverlay + FadeOverlay)
_ov := {alpha: 0, gui: ""}

; ╔══════════════════════════════════════════════════════════════╗
; ║                         HOTKEYS                             ║
; ║  F23              → Open the backup folder in Explorer     ║
; ║  Shift + F23      → Copy selected file(s) to backup        ║
; ║  Ctrl  + F23      → Move selected file(s) to backup        ║
; ║  Alt   + F23      → Save clipboard text as timestamped file║
; ╚══════════════════════════════════════════════════════════════╝

; Shift+F23 and Ctrl+F23 are scoped to Explorer windows (file selection only makes sense there)
#HotIf WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass")
+F23:: BackupSelectedFiles()
^F23:: MoveSelectedFiles()
#HotIf

; These two work globally
F23::  OpenBackupFolder()
!F23:: BackupClipboard()


; ╔══════════════════════════════════════════════════════════════╗
; ║                       TRAY ICON SETUP                       ║
; ║                                                             ║
; ║  The icon is pulled from shell32.dll, which ships with      ║
; ║  every version of Windows — no external file needed.        ║
; ║                                                             ║
; ║  To use a custom .ico file instead, replace the            ║
; ║  TraySetIcon line with:                                     ║
; ║    TraySetIcon("C:\path\to\your\icon.ico")                 ║
; ╚══════════════════════════════════════════════════════════════╝

; Folder icon from the built-in Windows shell icon library
TraySetIcon("shell32.dll", 4)

; Tooltip text shown when hovering over the tray icon
A_IconTip := "Backup Utility`n`nF23           Open backup folder`nShift+F23   Copy selected files`nCtrl+F23    Move selected files`nAlt+F23     Save clipboard"

; Build the right-click tray menu
Tray := A_TrayMenu
Tray.Delete()                                          ; Remove default AHK items

Tray.Add("Open Backup Folder",  (*) => OpenBackupFolder())
Tray.Add("Save Clipboard",      (*) => BackupClipboard())
Tray.Add()                                             ; Separator
Tray.Add("Delete All Backups",  (*) => DeleteAllBackups())
Tray.Add()                                             ; Separator
Tray.Add("Exit",                (*) => ExitApp())

Tray.Default    := "Open Backup Folder"                ; Bold item — triggered on double-click
Tray.ClickCount := 2                                   ; Single-click shows tooltip; double-click runs default


; ──────────────────────────────────────────────────────────────
; FUNCTION: Backup selected file(s) from the active Explorer window
; ──────────────────────────────────────────────────────────────
BackupSelectedFiles() {
    global BackupFolder
    EnsureFolder(BackupFolder)

    files := GetExplorerSelectedFiles()

    if files.Length = 0 {
        Notify("No Selection", "Select one or more files in Explorer first.", false)
        return
    }

    copied := 0
    failed := 0
    for filePath in files {
        SplitPath(filePath, &fileName)
        try {
            dest := UniqueDestPath(BackupFolder "\" fileName)
            FileCopy(filePath, dest)
            copied++
        } catch {
            failed++
        }
    }

    if copied > 0 {
        msg := copied " file(s) copied to backup folder."
        if failed > 0
            msg .= "`n(" failed " could not be copied.)"
        Notify("Backup Complete", msg, true)
    } else {
        Notify("Backup Failed", "None of the selected files could be copied.", false)
    }
}


; ──────────────────────────────────────────────────────────────
; FUNCTION: Move selected file(s) from the active Explorer window
; ──────────────────────────────────────────────────────────────
MoveSelectedFiles() {
    global BackupFolder
    EnsureFolder(BackupFolder)

    files := GetExplorerSelectedFiles()

    if files.Length = 0 {
        Notify("No Selection", "Select one or more files in Explorer first.", false)
        return
    }

    moved := 0
    failed := 0
    for filePath in files {
        SplitPath(filePath, &fileName)
        try {
            dest := UniqueDestPath(BackupFolder "\" fileName)
            FileMove(filePath, dest)
            moved++
        } catch {
            failed++
        }
    }

    if moved > 0 {
        msg := moved " file(s) moved to backup folder."
        if failed > 0
            msg .= "`n(" failed " could not be moved.)"
        Notify("Move Complete", msg, true)
    } else {
        Notify("Move Failed", "None of the selected files could be moved.", false)
    }
}


; ──────────────────────────────────────────────────────────────
; FUNCTION: Save current clipboard text as a timestamped .txt file
; ──────────────────────────────────────────────────────────────
BackupClipboard() {
    global BackupFolder
    EnsureFolder(BackupFolder)

    content := A_Clipboard
    if Trim(content) = "" {
        Notify("Empty Clipboard", "The clipboard has no text to save.", false)
        return
    }

    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    fileName  := "clipboard_" timestamp ".txt"
    filePath  := BackupFolder "\" fileName

    try {
        FileAppend(content, filePath, "UTF-8")
        Notify("Clipboard Saved", "Saved as:`n" fileName, true)
    } catch as err {
        Notify("Save Failed", "Error: " err.Message, false)
    }
}


; ──────────────────────────────────────────────────────────────
; FUNCTION: Open the backup folder in Windows Explorer
; ──────────────────────────────────────────────────────────────
OpenBackupFolder() {
    global BackupFolder
    EnsureFolder(BackupFolder)
    Run('explorer.exe "' BackupFolder '"')
}


; ──────────────────────────────────────────────────────────────
; FUNCTION: Delete all files in the backup folder (tray only)
;           Asks for confirmation before doing anything.
; ──────────────────────────────────────────────────────────────
DeleteAllBackups() {
    global BackupFolder
    if !DirExist(BackupFolder) {
        MsgBox("The backup folder does not exist yet.`n`n" BackupFolder, "Delete All Backups", "OK Icon!")
        return
    }

    count := 0
    loop files BackupFolder "\*.*"
        count++

    if count = 0 {
        MsgBox("The backup folder is already empty.", "Delete All Backups", "OK Icon!")
        return
    }

    answer := MsgBox(
        "This will permanently delete all " count " file(s) in:`n`n" BackupFolder "`n`nThis cannot be undone. Continue?",
        "Delete All Backups",
        "YesNo Icon! Default2"   ; Default button is No
    )
    if answer != "Yes"
        return

    failed := 0
    loop files BackupFolder "\*.*" {
        try FileDelete(A_LoopFileFullPath)
        catch
            failed++
    }

    if failed = 0
        Notify("Backup Cleared", "All files deleted from backup folder.", true)
    else
        Notify("Partial Delete", failed " file(s) could not be deleted.", false)
}


; ══════════════════════════════════════════════════════════════
; HELPERS
; ══════════════════════════════════════════════════════════════

; Returns an array of fully-qualified paths of files selected in
; the currently active Explorer window.
GetExplorerSelectedFiles() {
    files := []
    try {
        for win in ComObject("Shell.Application").Windows() {
            if win.hwnd == WinExist("A") {
                for item in win.Document.SelectedItems()
                    files.Push(item.Path)
                break
            }
        }
    }
    return files
}

; Creates the folder (and any missing parents) if it doesn't exist.
EnsureFolder(path) {
    if !DirExist(path)
        DirCreate(path)
}

; Given a full destination path, returns a path that does not yet exist.
; If "C:\Backup\report.pdf" is taken, returns "C:\Backup\report_2026-04-01_14-32-05.pdf".
UniqueDestPath(destPath) {
    if !FileExist(destPath)
        return destPath
    SplitPath(destPath, , &dir, &ext, &stem)
    ts      := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    newName := stem "_" ts (ext != "" ? "." ext : "")
    return dir "\" newName
}

; Plays a sound and flashes a translucent overlay at screen centre.
;   success = true  → two ascending beeps + green ✓
;   success = false → one low error beep  + red ✗
Notify(title, body, success := true) {
    if success {
        SoundBeep(880, 100)
        SoundBeep(1320, 180)
    } else {
        SoundBeep(380, 450)
    }
    FlashOverlay(success)
}

; Shows a 140×140 px square at screen centre, holds for ~400 ms,
; then fades out over ~440 ms.  Click-through so it never interrupts work.
; State is kept in the script-level _ov object so FadeOverlay can reach it.
FlashOverlay(success := true) {
    global _ov
    SetTimer(FadeOverlay, 0)        ; Cancel any in-progress fade
    if IsObject(_ov.gui)
        try _ov.gui.Destroy()

    bgColor := success ? "27AE60" : "C0392B"   ; green / red
    symbol  := success ? "✓" : "✗"

    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = click-through
    g.BackColor := bgColor
    g.SetFont("s52 cFFFFFF Bold", "Segoe UI")
    g.Add("Text", "w140 h140 Center +0x200", symbol)      ; 0x200 = vertically centred

    cx := (A_ScreenWidth  - 140) // 2
    cy := (A_ScreenHeight - 140) // 2
    g.Show("W140 H140 X" cx " Y" cy " NoActivate")
    WinSetTransparent(220, g)

    _ov := {alpha: 220, gui: g}
    SetTimer(FadeOverlay, -400)     ; Begin fade after 400 ms hold
}

; Called as a chain of one-shot timers (-40 ms each).
; Decrements alpha by 20 per step; stops itself when fully transparent.
FadeOverlay() {
    global _ov
    _ov.alpha -= 20
    if _ov.alpha <= 0 {
        try _ov.gui.Destroy()
        _ov.gui := ""
        return                      ; Don't reschedule — fade complete
    }
    try WinSetTransparent(_ov.alpha, _ov.gui)
    SetTimer(FadeOverlay, -40)      ; Schedule next step
}
