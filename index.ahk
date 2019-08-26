#SingleInstance, force
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include <workspace/WorkspaceManager>

elevateAdmin() {
    fullCmdLine := DllCall("GetCommandLine", "str")
    fullCmdLine := StrReplace(fullCmdLine, "exe""", "exe"" /restart")

    if (!A_IsAdmin) {
        Run *RunAs %fullCmdLine%
        ExitApp
    }
}

runApp() {
    FileName := "WorkSpaceConfig.json"

    if (A_Args[1]) {
        FileName := A_Args[1]
    }

    try {
        ; Move windows based on config file
        try {
            wsm := new WorkspaceManager(FileName)
            wsm.loadConfig()
            wsm.runConfig()
        } catch err {
            MsgBox, % 0x30, % "Can't Manage Workspace", % err.Message
        }
    } catch err {
        MsgBox % "Error Starting: " . err.Message
        ExitApp
    }
}

; elevateAdmin()
runApp()