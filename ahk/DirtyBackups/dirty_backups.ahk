#Requires AutoHotkey v2.0
#SingleInstance Force

; ╔══════════════════════════════════════════════════════════════╗
; ║                     USER CONFIGURATION                       ║
; ║  Edit the path below to point to your desired backup folder. ║
; ║  Use a full absolute path. Examples:                         ║
; ║    BackupFolder := "C:\Users\YourName\Backup"                ║
; ║    BackupFolder := "D:\MyBackups"                            ║
; ╚══════════════════════════════════════════════════════════════╝

BackupFolder := "A:\DIRTY_BACKUPS"

; Shared state for the fade overlay (used by FlashOverlay + FadeOverlay)
_ov := {alpha: 0, gui: ""}

; ╔══════════════════════════════════════════════════════════════╗
; ║                         HOTKEYS                              ║
; ║  F23              → Open the backup folder in Explorer       ║
; ║  Shift + F23      → Copy selected file(s) to backup          ║
; ║  Ctrl  + F23      → Move selected file(s) to backup          ║
; ║  Alt   + F23      → Save clipboard text as timestamped file  ║
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
; ║                       TRAY ICON SETUP                        ║
; ║                                                              ║
; ║  The icon is pulled from shell32.dll, which ships with       ║
; ║  every version of Windows — no external file needed.         ║
; ║                                                              ║
; ║  To use a custom .ico file instead, replace the              ║
; ║  TraySetIcon line with:                                      ║
; ║    TraySetIcon("C:\path\to\your\icon.ico")                   ║
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
        Notify("error", "No Files")
        return
    }

    copied  := 0
    skipped := 0
    failed  := 0
    for filePath in files {
        SplitPath(filePath, &fileName)
        try {
            if IsDuplicate(filePath, BackupFolder) {
                skipped++
                continue
            }
            dest := UniqueDestPath(BackupFolder "\" fileName)
            FileCopy(filePath, dest)
            copied++
        } catch {
            failed++
        }
    }

    if copied = 0 && skipped > 0 && failed = 0 {
        Notify("skip", "Skipped")
    } else if copied > 0 {
        Notify("ok", "Copied")
    } else {
        Notify("error", "Failed")
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
        Notify("error", "No Files")
        return
    }

    moved   := 0
    skipped := 0
    failed  := 0
    for filePath in files {
        SplitPath(filePath, &fileName)
        try {
            if IsDuplicate(filePath, BackupFolder) {
                skipped++
                continue
            }
            dest := UniqueDestPath(BackupFolder "\" fileName)
            FileMove(filePath, dest)
            moved++
        } catch {
            failed++
        }
    }

    if moved = 0 && skipped > 0 && failed = 0 {
        Notify("skip", "Skipped")
    } else if moved > 0 {
        Notify("ok", "Moved")
    } else {
        Notify("error", "Failed")
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
        Notify("error", "Empty")
        return
    }

    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    fileName  := "clipboard_" timestamp ".txt"
    filePath  := BackupFolder "\" fileName

    try {
        FileAppend(content, filePath, "UTF-8")
        Notify("ok", "Saved")
    } catch as err {
        Notify("error", "Failed")
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
        Notify("ok", "Cleared")
    else
        Notify("error", "Partial")
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

; Returns true if an identical copy of srcPath already exists anywhere in destFolder.
; "Identical" means same file size AND same last-modified timestamp — no file reading needed.
IsDuplicate(srcPath, destFolder) {
    srcSize := FileGetSize(srcPath)
    srcTime := FileGetTime(srcPath, "M")
    loop files destFolder "\*.*" {
        if FileGetSize(A_LoopFileFullPath) = srcSize
            && FileGetTime(A_LoopFileFullPath, "M") = srcTime
            return true
    }
    return false
}

; Plays a sound and flashes a labelled overlay at screen centre.
;   state = "ok"    → two ascending beeps + blue  ✓
;   state = "skip"  → one mid beep         + amber ~
;   state = "error" → one low error beep   + red   ✗
; label is a short word shown beneath the symbol on the overlay (e.g. "Copied").
Notify(state, label) {
    if state = "ok" {
        SoundBeep(880, 100)
        SoundBeep(1320, 180)
    } else if state = "skip" {
        SoundBeep(660, 200)
    } else {
        SoundBeep(380, 450)
    }
    FlashOverlay(state, label)
}

; Shows a 160×170 px square at screen centre with a symbol and short label,
; holds for ~600 ms, then fades out over ~440 ms. Click-through throughout.
FlashOverlay(state, label) {
    global _ov
    SetTimer(FadeOverlay, 0)
    if IsObject(_ov.gui)
        try _ov.gui.Destroy()

    if state = "ok" {
        bgColor := "2471A3"   ; blue
        symbol  := "✓"
    } else if state = "skip" {
        bgColor := "CA6F1E"   ; amber
        symbol  := "~"
    } else {
        bgColor := "C0392B"   ; red
        symbol  := "✗"
    }

    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = click-through
    g.BackColor := bgColor

    g.SetFont("s46 cFFFFFF Bold", "Segoe UI")
    g.Add("Text", "w160 h95 Center +0x200", symbol)       ; 0x200 = vertically centred

    g.SetFont("s13 cFFFFFF Bold", "Segoe UI")
    g.Add("Text", "w160 h35 Center +0x200", label)

    cx := (A_ScreenWidth  - 160) // 2
    cy := (A_ScreenHeight - 170) // 2
    g.Show("W160 H170 X" cx " Y" cy " NoActivate")
    WinSetTransparent(220, g)

    _ov := {alpha: 220, gui: g}
    SetTimer(FadeOverlay, -600)     ; Begin fade after 600 ms hold
}

; Called as a chain of one-shot timers (-40 ms each).
; Decrements alpha by 20 per step; stops itself when fully transparent.
FadeOverlay() {
    global _ov
    _ov.alpha -= 20
    if _ov.alpha <= 0 {
        try _ov.gui.Destroy()
        _ov.gui := ""
        return
    }
    try WinSetTransparent(_ov.alpha, _ov.gui)
    SetTimer(FadeOverlay, -40)
}
