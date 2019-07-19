class MonitorManager
{
    class GetMonitorInfo extends MonitorManager.Functor
    {
        Call(self, MonitorNum)
        {
            ; Get Monitor Info
            SysGet, MonitorInfo_Name, MonitorName, % MonitorNum
            SysGet, MonitorInfo_, Monitor, % MonitorNum
            SysGet, MonitorWAInfo_, MonitorWorkArea, % MonitorNum
            MonitorInfo_Width := Max(Abs(MonitorInfo_Left), Abs(MonitorInfo_Right)) - Min(Abs(MonitorInfo_Left), Abs(MonitorInfo_Right))
            MonitorInfo_Height := Max(Abs(MonitorInfo_Top), Abs(MonitorInfo_Bottom)) - Min(Abs(MonitorInfo_Top), Abs(MonitorInfo_Bottom))
            MonitorWAInfo_Height := Max(Abs(MonitorWAInfo_Left), Abs(MonitorWAInfo_Right)) - Min(Abs(MonitorWAInfo_Left), Abs(MonitorWAInfo_Right))
            MonitorWAInfo_Width := Max(Abs(MonitorWAInfo_Top), Abs(MonitorWAInfo_Bottom)) - Min(Abs(MonitorWAInfo_Top), Abs(MonitorWAInfo_Bottom))

            ; Monitor info not found, default to PRIMARY monitor
            if (!MonitorInfo_Width)
            {
                return MonitorManager.GetMonitorInfo(1)
            }

            MonInfo := { Index: MonitorNum
                , Name: MonitorInfo_Name }
            MonInfo.Offset := { Left: MonitorInfo_Left 
                , Right: MonitorInfo_Right
                , Top: MonitorInfo_Top
                , Bottom: MonitorInfo_Bottom
                , Width: MonitorInfo_Width
                , Height: MonitorInfo_Height }
            
            MonInfo.WorkArea := { Left: MonitorWAInfo_Left
                , Right: MonitorWAInfo_Right
                , Top: MonitorWAInfo_Top
                , Bottom: MonitorWAInfo_Bottom
                , Width: MonitorWAInfo_Width
                , Height: MonitorWAInfo_Height }

            return MonInfo
        }
    }

    class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}