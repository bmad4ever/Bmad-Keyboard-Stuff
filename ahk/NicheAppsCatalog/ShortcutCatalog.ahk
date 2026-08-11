#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================================
;  Shortcut Catalog
;  Lists every .lnk in this script's folder (name + icon) with a user-written
;  description beside it. Descriptions are locked by default; click
;  "Unlock Descriptions" to edit them, then double-click a description cell.
;
;  Data is stored in "descriptions.ini" next to this script, keyed by shortcut
;  filename. (Avoid % in shortcut filenames: % is a wildcard in INI keys.)
;
;  Usage:
;    Double-click a shortcut's name  -> launch the app
;    Double-click a description cell -> edit it (only while unlocked)
;    Enter while editing             -> save
;    Esc while editing               -> cancel
;    Close the window (X)            -> hide to tray (script keeps running)
;    Tray menu                       -> show/hide the catalog
; ============================================================================

INI_FILE := A_ScriptDir "\descriptions.ini"
ICON_FILE := A_ScriptDir "\catalog.ico"

TraySetIcon(ICON_FILE)

gFiles    := CollectFiles()
gUnlocked := false
gEditing  := false
gEditRow  := 0
gIml      := 0

BuildGui()

; ============================================================================
BuildGui()
{
    global gGui, gLV, gEdit, gStatus

    gGui := Gui("-DPIScale ToolWindow", "Shortcut Catalog")

    ; give the window the same icon as the tray (WM_SETICON 0x0080)
    hBig := DllCall("user32\LoadImageW", "Ptr", 0, "Str", ICON_FILE, "UInt", 1,
                    "Int", 32, "Int", 32, "UInt", 0x10)
    hSmall := DllCall("user32\LoadImageW", "Ptr", 0, "Str", ICON_FILE, "UInt", 1,
                      "Int", 16, "Int", 16, "UInt", 0x10)
    if hBig
        SendMessage(0x0080, 1, hBig, gGui.Hwnd)      ; ICON_BIG
    if hSmall
        SendMessage(0x0080, 0, hSmall, gGui.Hwnd)    ; ICON_SMALL

    gGui.Add("Text", "xm w680", "Shortcuts in: " A_ScriptDir)
    btnUnlock := gGui.Add("Button", "xm w180", "Unlock Descriptions")
    btnUnlock.OnEvent("Click", ToggleLock)
    btnRefresh := gGui.Add("Button", "x+8 w90", "Refresh")
    btnRefresh.OnEvent("Click", (*) => Refresh())

    gStatus := gGui.Add("Text", "xm w680", 'Descriptions are locked. Click "Unlock Descriptions" to edit them.')

    gLV := gGui.Add("ListView", "xm w680 r14 NoSort -LV0x10", ["App", "Description"])
    gLV.ModifyCol(1, 240)
    gLV.ModifyCol(2, 430)

    gEdit := gGui.Add("Edit", "Hidden -TabStop")

    btnOK := gGui.Add("Button", "Hidden Default", "OK")
    btnOK.OnEvent("Click", (*) => EndEdit())

    gLV.OnNotify(-3, OnLVDoubleClick)      ; NM_DBLCLK
    gEdit.OnEvent("LoseFocus", OnEditLoseFocus)

    gGui.OnEvent("Close", (*) => HideCatalog())
    gGui.OnEvent("Escape", (*) => CancelEdit())

    BuildTrayMenu()
    Populate()
}

; ============================================================================
BuildTrayMenu()
{
    A_TrayMenu.Add("&Show Catalog", ShowCatalog)
    A_TrayMenu.Add("&Hide Catalog", HideCatalog)
    A_TrayMenu.Default := "&Show Catalog"
}

; ============================================================================
ShowCatalog(*)
{
    global gGui, gLV
    gGui.Show()
    gLV.Modify(1)                  ; force a repaint so icons draw
    WinActivate gGui
}

; ============================================================================
HideCatalog(*)
{
    global gGui, gEditing
    if gEditing
        CancelEdit()
    gGui.Hide()
}

; ============================================================================
CollectFiles()
{
    files := []
    Loop Files, A_ScriptDir "\*.lnk"
        files.Push({ Name: A_LoopFileName, Path: A_LoopFilePath })

    ; insertion sort by name, case-insensitive (Array.Sort doesn't exist in v2.0.x)
    Loop files.Length - 1
    {
        i := A_Index + 1
        v := files[i]
        j := i - 1
        while j >= 1 and StrCompare(files[j].Name, v.Name) > 0
        {
            files[j + 1] := files[j]
            j -= 1
        }
        files[j + 1] := v
    }
    return files
}

; ============================================================================
Populate()
{
    global gFiles, gLV, gIml

    if gIml
        IL_Destroy(gIml)

    gLV.Opt("-Redraw")
    gLV.Delete()

    gIml := IL_Create(gFiles.Length, false, 32)
    gLV.SetImageList(gIml, 0)      ; LVSIL_NORMAL
    gLV.SetImageList(gIml, 1)      ; LVSIL_SMALL

    sfi := Buffer(A_PtrSize + 688)
    for f in gFiles
    {
        icon := 9999999
        ; 0x100 = SHGFI_ICON (large 32x32); resolves the .lnk target's icon
        if DllCall("shell32\SHGetFileInfoW", "Str", f.Path, "UInt", 0, "Ptr", sfi,
                   "UInt", sfi.Size, "UInt", 0x100)
        {
            hIcon := NumGet(sfi, 0, "Ptr")
            if hIcon
            {
                icon := DllCall("comctl32\ImageList_ReplaceIcon", "Ptr", gIml, "Int", -1, "Ptr", hIcon) + 1
                DllCall("user32\DestroyIcon", "Ptr", hIcon)
            }
        }
        desc := IniRead(INI_FILE, f.Name, "description", "")
        gLV.Add("Icon" icon, DisplayName(f.Name), desc)
    }

    gLV.Opt("+Redraw")
    gLV.ModifyCol(1, "AutoHdr")
    gLV.ModifyCol(2, "AutoHdr")
}

; ============================================================================
; Clean filename into a readable app name: strip the ".lnk" extension, a
; trailing " - Shortcut", and a trailing ".exe"/".EXE".
;   "Audacity.exe - Shortcut.lnk" -> "Audacity"
;   "Launch TuxGuitar.lnk"        -> "Launch TuxGuitar"
; ============================================================================
DisplayName(fname)
{
    SplitPath(fname, , , , &name)
    if SubStr(name, -11) = " - Shortcut"
        name := SubStr(name, 1, -11)
    if StrLower(SubStr(name, -4)) = ".exe"
        name := SubStr(name, 1, -4)
    return name
}

; ============================================================================
Refresh()
{
    global gFiles, gEditing
    if gEditing
        EndEdit()
    gFiles := CollectFiles()
    Populate()
}

; ============================================================================
ToggleLock(Ctrl, *)
{
    global gUnlocked, gStatus, gLV
    gUnlocked := !gUnlocked
    if gUnlocked
    {
        Ctrl.Text := "Lock Descriptions"
        gStatus.Text := "Unlocked - double-click a description to edit it. Enter saves, Esc cancels."
    }
    else
    {
        Ctrl.Text := "Unlock Descriptions"
        gStatus.Text := 'Descriptions are locked. Click "Unlock Descriptions" to edit them.'
    }
    gLV.Focus()
}

; ============================================================================
; Double-click on a row: name column launches the app, description column
; starts inline editing (only while unlocked).
; ============================================================================
OnLVDoubleClick(Ctrl, lParam)
{
    global gFiles, gUnlocked, gEditing

    iItemOff := ((2 * A_PtrSize + 4) + A_PtrSize - 1) // A_PtrSize * A_PtrSize
    iItem    := NumGet(lParam, iItemOff, "Int")
    iSubItem := NumGet(lParam, iItemOff + 4, "Int")

    if iItem < 0
        return

    row := iItem + 1

    if iSubItem = 0
    {
        try
            Launch(gFiles[row].Path)
        catch
            MsgBox "Could not launch: " gFiles[row].Path
        return
    }

    if not gUnlocked
    {
        MouseGetPos(&mx, &my)
        ToolTip 'Locked - click "Unlock Descriptions" first.', mx, my
        SetTimer () => ToolTip(), -1500
        return
    }

    if not gEditing
        StartEdit(row)
}

; ============================================================================
StartEdit(row)
{
    global gLV, gEdit, gEditing, gEditRow

    if row < 1 or row > gLV.GetCount()
        return

    gEditing  := true
    gEditRow  := row
    gEdit.Text := gLV.GetText(row, 2)

    ; LVM_GETSUBITEMRECT (0x1038): left = LVIR_BOUNDS, top = subitem index
    rect := Buffer(16)
    NumPut("Int", 0, rect, 0)
    NumPut("Int", 1, rect, 4)
    SendMessage(0x1038, row - 1, rect, gLV.Hwnd)

    gLV.GetPos(&lvx, &lvy, &lvw, &lvh)
    cr := Buffer(16)
    DllCall("GetClientRect", "Ptr", gLV.Hwnd, "Ptr", cr)
    borderX := (lvw - NumGet(cr, 8, "Int")) // 2
    borderY := lvh - NumGet(cr, 12, "Int") - borderX

    ex := lvx + borderX + NumGet(rect, 0, "Int")
    ey := lvy + borderY + NumGet(rect, 4, "Int")
    ew := NumGet(rect, 8, "Int") - NumGet(rect, 0, "Int")
    eh := NumGet(rect, 12, "Int") - NumGet(rect, 4, "Int")

    gEdit.Move(ex, ey, ew, eh)
    gEdit.Visible := true
    gEdit.Focus()
    SendMessage(0x00B1, 0, -1, gEdit.Hwnd)   ; EM_SETSEL -> select all
}

; ============================================================================
EndEdit()
{
    global gLV, gEdit, gEditing, gEditRow, gFiles, INI_FILE

    if not gEditing
        return

    row  := gEditRow
    desc := gEdit.Text

    gEditing      := false
    gEdit.Visible := false

    if desc != gLV.GetText(row, 2)
    {
        gLV.Modify(row, "Col2", desc)
        IniWrite(desc, INI_FILE, gFiles[row].Name, "description")
    }

    gLV.Focus()
}

; ============================================================================
CancelEdit()
{
    global gLV, gEdit, gEditing

    if not gEditing
        return

    gEditing      := false
    gEdit.Visible := false
    gLV.Focus()
}

; ============================================================================
; Launch a shortcut. Run() mis-parses .lnk files whose name contains ".exe "
; (e.g. "Audacity.exe - Shortcut.lnk" -> program "Audacity.exe", args "- Shortcut.lnk").
; Resolving the target via WScript.Shell and launching it directly avoids that.
; ============================================================================
Launch(lnkPath)
{
    try
    {
        shell  := ComObject("WScript.Shell")
        sc     := shell.CreateShortcut(lnkPath)
        target := sc.TargetPath
        if target = ""
            throw
        workdir := sc.WorkingDirectory
        if workdir = ""
            SplitPath(target,, &workdir)
        Run Format('"{1}" {2}', target, sc.Arguments), workdir
    }
    catch
        Run '"' lnkPath '"'
}

; ============================================================================
OnEditLoseFocus(Ctrl, *)
{
    EndEdit()
}
