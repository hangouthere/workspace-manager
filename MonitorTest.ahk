#SingleInstance, force
#NoEnv
#Include <JSON>
#Include <MonitorManager>
#Include <WindowManager>

GUI_ID := ""
MonitorDebug := ""
OffsetDebug := ""
MonCount := ""

SysGet, MonCount, MonitorCount

ShowGui()
{
    global GUI_ID
    global MonitorDebug
    global OffsetDebug

    Gui Add, Edit, hWndhEdtValue vMonitorDebug x16 y40 w296 h364
    Gui Add, Text, x16 y8 w130 h23 +0x200 BackgroundTrans +E0x20  , Monitor Info
    Gui Add, Edit, hWndhEdtValue2 vOffsetDebug x320 y40 w281 h228 +Multi -Theme BackgroundTrans -0x40000 -0x800040 +E0x20 

    Gui Show, w609 h420, MonitorManager :: Monitor Debug Info

    ; Store GUI HWND for manipulation
    WinWait, A
    WinGet, hWnd, id
    GUI_ID := "ahk_id " . hWnd
}

UpdateMonitorInfo()
{
    global MonCount

    MonitorDebugVal := ""

    Loop, % MonCount
    {
        MonInfo := MonitorManager.GetMonitorInfo(A_INDEX)

        MonitorDebugVal .= "Monitor: " . A_INDEX . "`n" . JSON.Dump(MonInfo,, "`t") . "`n`n"
    }

    GuiControl,, MonitorDebug, % MonitorDebugVal
}

UpdateOffsetDebug(MonInfo)
{
    global GUI_ID

    T1o := MonitorManager.OffsetForMonitor({x: 250, y: 250}, MonInfo)
    T2o := MonitorManager.OffsetForMonitor({x: "50%", y: "50%"}, MonInfo)
    T3o := MonitorManager.OffsetForMonitor({x: -200, y: -200}, MonInfo)
    T1a := MonitorManager.AreaForMonitor({width: 250, height: 250}, MonInfo)
    T2a := MonitorManager.AreaForMonitor({width: "50%", height: "50%"}, MonInfo)
    T3a := MonitorManager.AreaForMonitor({width: -200, height: -200}, MonInfo)
    T1w := WindowManager.ConvertDimensions({x: 250, y: 250, width: 250, height: 250}, MonInfo)
    T2w := WindowManager.ConvertDimensions({x: "50%", y: "50%", width: "50%", height: "50%"}, MonInfo)
    T3w := WindowManager.ConvertDimensions({x: -200, y: -200, width: -200, height: -200}, MonInfo)
    T4w := WindowManager.ConvertDimensions({x: -400, y: -300, width: 400, height: 300}, MonInfo)

    GuiControl,, OffsetDebug, % "Monitor " . MonInfo.Index
        . "`nWork Area Start:`t" . MonInfo.WorkArea.Left . ", " . MonInfo.WorkArea.Top
        . "`nMonitor Size:`t" . MonInfo.Offset.Width . "x" . MonInfo.Offset.Height
        . "`nWork Area Size:`t" . MonInfo.WorkArea.Width . "x" . MonInfo.WorkArea.Height
        . "`nOffset Test:"
        . "`n  250, 250:`t" . T1o.x . ", " . T1o.y
        . "`n  50%, 50%:`t" . T2o.x . ", " . T2o.y
        . "`n  -200, -200:`t" . T3o.x . ", " . T3o.y
        . "`nArea Test:"
        . "`n  250, 250:`t" . T1a.width . "x" . T1a.height
        . "`n  50%, 50%:`t" . T2a.width . "x" . T2a.height
        . "`n  -200, -200:`t" . T3a.width . "x" . T3a.height
        . "`nWindowManager Test:"
        . "`n  250 all around:`t" . T1w.x . ", " . T1w.y . " | " . T1w.width . "x" . T1w.height
        . "`n  50% all around:`t" . T2w.x . ", " . T2w.y . " | " . T2w.width . "x" . T2w.height
        . "`n  -200 all around:`t" . T3w.x . ", " . T3w.y . " | " . T3w.width . "x" . T3w.height
        . "`n  -400-300@400x300:`t" . T4w.x . ", " . T4w.y . " | " . T4w.width . "x" . T4w.height
}

Demo()
{
    global MonCount
    Loop, % MonCount
    {
        global GUI_ID

        MonInfo := MonitorManager.GetMonitorInfo(A_INDEX)

        UpdateOffsetDebug(MonInfo)
        WinMove, % GUI_ID, , % MonInfo.WorkArea.Left, % MonInfo.WorkArea.Top
        Sleep, % 10 * 1000
    }
}

Start()
{
    ShowGui()
    UpdateMonitorInfo()
    Demo()

    ; SetTimer, UpdateDebugForMonitor, On
}

Start()

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; UpdateDebugForMonitor:
;     UpdateOffsetDebug()
; Return

MainWinLabelEscape:
MainWinLabelClose:
    ExitApp