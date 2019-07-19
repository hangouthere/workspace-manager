#Include <JSON>
#Include <MonitorManager>

SysGet, MonCount, MonitorCount

Loop, % MonCount
{
    MonInfo := MonitorManager.GetMonitorInfo(1)
    MsgBox, % "Monitor: " . A_INDEX . "`n" . JSON.Dump(MonInfo,, "`t")
}