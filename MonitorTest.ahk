#SingleInstance, force
#NoEnv
#Include <JSON>
#Include <MonitorManager>

SysGet, MonCount, MonitorCount

Gui MainWinName: New, +LabelMainWinLabel +hWndhMainWnd -MinimizeBox -MaximizeBox
Gui Color, 0x3C3C3C
Gui Add, Edit, vMonitorDebug x16 y40 w561 h289
Gui Font, s18 c0xE5E5E5
Gui Add, Text, x16 y8 w130 h23 +0x200 BackgroundTrans +E0x20, Monitor Info
Gui Font

Gui Show, w593 h350, Window

MonitorDebugVal := ""

Loop, % MonCount
{
    MonInfo := MonitorManager.GetMonitorInfo(A_INDEX)

    MonitorDebugVal .= "Monitor: " . A_INDEX . "`n" . JSON.Dump(MonInfo,, "`t") . "`n`n"
}

GuiControl,, MonitorDebug, % MonitorDebugVal
Return

MainWinLabelEscape:
MainWinLabelClose:
    ExitApp