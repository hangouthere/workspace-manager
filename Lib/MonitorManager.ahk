class MonitorTranslator
{
    class GetMonitorInfo extends MonitorTranslator.Functor
    {
        Call(self, monitor)
        {
            ; Get Monitor Info
            SysGet, MonitorInfo_, Monitor, % MonitorNum
            SysGet, MonitorWAInfo_, MonitorWorkArea, % MonitorNum
            MonitorInfo_Width := Abs(MonitorInfo_Right) - Abs(MonitorInfo_Left)
            MonitorInfo_Height := Abs(MonitorInfo_Bottom) - Abs(MonitorInfo_Top)
            MonitorWAInfo_Width := Abs(MonitorWAInfo_Right) - Abs(MonitorWAInfo_Left)
            MonitorWAInfo_Height := Abs(MonitorWAInfo_Bottom) - Abs(MonitorWAInfo_Top)

            ; Monitor info not found, default to PRIMARY monitor
            if (!MonitorInfo_Width)
            {
                return this._getMonitorInfo(1)
            }

            MonInfo := {}
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