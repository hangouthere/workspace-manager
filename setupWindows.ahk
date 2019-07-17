#Include <JSON>
#Include <WindowManager>

; Move windows based on config file
try {
    WindowConfig := WindowManager.ConfigFromFile("WindowConfig.json")
    WindowManager.RunConfig(WindowConfig)
} catch err {
    MsgBox ,,Can't Manage Windows, % err.Message
}