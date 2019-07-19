class MonitorManager
{
    DetectValue(InputVal)
    {
        ; Special Case Processing
        if InputVal is integer
        {
            return InputVal
        }

        RegExMatch(InputVal, "O)^([0-9]{1,})(\%?)$" , DimMatcher)
        Size := DimMatcher.Value(1)
        IsPercent := DimMatcher.Value(2) = "%" ? True : False

        return { IsPercent: IsPercent, Size: Size }
    }

    class GetMonitorInfo extends MonitorManager.Functor
    {
        Call(self, MonitorNum := 1)
        {
            ; Get Monitor Info
            SysGet, MonitorInfo_Name, MonitorName, % MonitorNum
            SysGet, MonitorInfo_, Monitor, % MonitorNum
            SysGet, MonitorWAInfo_, MonitorWorkArea, % MonitorNum
            MonitorInfo_Width := Max(Abs(MonitorInfo_Left), Abs(MonitorInfo_Right)) - Min(Abs(MonitorInfo_Left), Abs(MonitorInfo_Right))
            MonitorInfo_Height := Max(Abs(MonitorInfo_Top), Abs(MonitorInfo_Bottom)) - Min(Abs(MonitorInfo_Top), Abs(MonitorInfo_Bottom))
            MonitorWAInfo_Width := Max(Abs(MonitorWAInfo_Left), Abs(MonitorWAInfo_Right)) - Min(Abs(MonitorWAInfo_Left), Abs(MonitorWAInfo_Right))
            MonitorWAInfo_Height := Max(Abs(MonitorWAInfo_Top), Abs(MonitorWAInfo_Bottom)) - Min(Abs(MonitorWAInfo_Top), Abs(MonitorWAInfo_Bottom))

            ; Monitor info not found
            if (!MonitorInfo_Width)
            {
                return
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

    class OffsetForMonitor extends MonitorManager.Functor
    {
        Call(self, Coords, MonitorInfo, WorkArea := true)
        {
            MonInfo := WorkArea ? MonitorInfo.WorkArea : MonitorInfo.Offset
            OutCoords := Coords.Clone()

            ; Hydrate into advanced value
            valX := MonitorManager.DetectValue(OutCoords.x)
            valY := MonitorManager.DetectValue(OutCoords.y)

            ; Calculate Initial Percentage Offset
            if (valX.IsPercent)
            {
                OutCoords.x := MonInfo.Width * (valX.Size / 100)
            }

            if (valY.IsPercent)
            {
                OutCoords.y := MonInfo.Height * (valY.Size / 100)
            }

            ; Apply Offset based on Monitor Info
            OutCoords.x += MonInfo.Left
            OutCoords.y += MonInfo.Top

            OutCoords.x := Round(OutCoords.x)
            OutCoords.y := Round(OutCoords.y)

            return OutCoords
        }        
    }

    class AreaForMonitor extends MonitorManager.Functor
    {
        Call(self, Dimensions, MonitorInfo, WorkArea := true)
        {
            MonInfo := WorkArea ? MonitorInfo.WorkArea : MonitorInfo.Offset
            OutDimensions := Dimensions.Clone()

            ; Hydrate into advanced value
            valWidth := MonitorManager.DetectValue(OutDimensions.width)
            valHeight := MonitorManager.DetectValue(OutDimensions.height)

            ; Calculate Initial Percentage Offset
            if (valWidth.IsPercent)
            {
                OutDimensions.width := MonInfo.Width * (valWidth.Size / 100)
            }

            if (valHeight.IsPercent)
            {
                OutDimensions.height := MonInfo.Height * (valHeight.Size / 100)
            }

            OutDimensions.width := Round(Abs(OutDimensions.width))
            OutDimensions.height := Round(Abs(OutDimensions.height))

            return OutDimensions
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