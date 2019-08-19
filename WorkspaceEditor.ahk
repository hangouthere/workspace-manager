#SingleInstance, force
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 2

#Include <gui/ManagerGUI>

APP_NAME := "WorkSpace Manager"
APP_VERSION := "v1.0.0"

elevateAdmin() {
    fullCmdLine := DllCall("GetCommandLine", "str")
    fullCmdLine := StrReplace(fullCmdLine, "exe""", "exe"" /restart")

    if (!A_IsAdmin) {
        Run *RunAs %fullCmdLine%
        ExitApp
    }
}

runApp() {
    global wseGui

    FileName := "WorkSpaceConfig.json"

    if (A_Args[1]) {
        FileName := A_Args[1]
    }

    try {
        wseGui := new ManagerGUI(FileName)
        wseGui.Show()
    } catch err {
        MsgBox % "Error Starting: " . err.Message
        ExitApp
    }
}

wseGui := 0

elevateAdmin()
runApp()

return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GuiClose:
    MouseManager.ResetCursor()

    ExitApp
return

~LButton::
    wseGui.onLeftMouseButton()
return

^b::
    if WinActive(wseGui.gui.ident) {
        wseGui.mainMenu.mnu_addBlankEntry()
    }
return

^l::
    if WinActive(wseGui.gui.ident) {
        wseGui.mainMenu.mnu_openWorkspace()
    }
return

^s::
    if WinActive(wseGui.gui.ident) {
        wseGui.mainMenu.mnu_saveEntry()
    }
return

^r::
    if WinActive(wseGui.gui.ident) {
        wseGui.mainMenu.mnu_runWorkspace()
    }
return