#Include <JSON>
#Include <MonitorManager>

SysGet, MonCount, MonitorCount

Loop, % MonCount
{
    MonInfo := MonitorManager.GetMonitorInfo(A_INDEX)
    MsgBox, % "Monitor: " . A_INDEX . "`n" . JSON.Dump(MonInfo,, "`t")
}