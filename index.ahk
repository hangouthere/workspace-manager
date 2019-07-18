#SingleInstance, force
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include <JSON>
#Include <WindowManager>

FileName := "WindowConfig.json"

; Detect command line config file entry
if (A_Args.Length() > 0)
{
    FileName := A_Args[1]
}

; Move windows based on config file
try {
    WindowConfig := WindowManager.ConfigFromFile(FileName)
    WindowManager.RunConfig(WindowConfig)
} catch err {
    MsgBox, % 0x30, % "Can't Manage Windows", % err.Message
}