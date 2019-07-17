#Include <JSON>

/**
 * Lib: WindowManager.ahk
 *     Manage Windows with AutoLaunch and other features (TBD).
 * Version:
 *     v0.0.1 [updated 07/17/2019 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include WindowManager.ahk or copy into a function library folder and then
 *     use #Include <WindowManager>
 * Links:
 *     GitHub:     - TBD
 *     Forum Topic - TBD
 *     Email:      - nfg.codex <at> outlook <dot> com
 */

class WindowManager 
{
     /**
	  * Method: FromFile
	  *     Loads a JSON file and parses
      * Author: nfgCodex
	  * Syntax:
	  *     obj := JSON.FromFile( FileName )
	  * Parameter(s):
	  *     obj        [retval] - AHK Object representation of JSON
	  *     FileName       [in] - string FileName to load and parse
	  */
	class ConfigFromFile extends JSON.Functor
	{
		Call(self, FileName)
		{
			FileObj := FileOpen(FileName, "r")
			if !IsObject(FileObj)
			{
				throw Exception("Can't open " . FileName . " for reading.", -1)
			}

			try {	
			    FileContents := FileObj.Read()
			    return JSON.Load(FileContents)
			} catch e {
				throw Exception("Error parsing JSON from " . FileName, -1)
			}
		}
	}
    
    /**
	 * Method: RunConfig
	 *     Iterates the config file, and launches/places windows based on structure of said config.
	 * Syntax:
	 *     WindowManager.RunConfig( wCfg )
	 * Parameter(s):
	 *     wCfg       [retval] - Window Config data struct
	 */
    class RunConfig extends JSON.Functor
	{
        Call(self, config)
        {
            ; Loop over every config entry
            For idx, WindowCfg in config
            {
                identifier := this.DetectWindow(WindowCfg.identifier, WindowCfg.executable)
                this.MoveWindow(identifier, WindowCfg.dimensions)
            }
        }

        DetectWindow(identifier, executable)
        {
            PID := 0
            hWnd := identifier ? WinExist(identifier) : 0

            ; No Identifier supplied means to force launch
            ; OR
            ; Identifier doesn't match a window
            if (!identifier or !hWnd)
            {
                Run, % executable,,, PID

                if (!identifier)
                {
                    identifier := "ahk_pid " . PID
                }
            } 
            else
            {
                identifier := "ahk_id " . hWnd
            }

            WinWaitActive, % identifier

            return identifier
        }

        _calcDimensionForMonitor(MonitorNum, InputVal, Axis := "x", IsOffset := True)
        {
            Size := 0

            ; Get Monitor Info
            SysGet, MonitorInfo_, MonitorWorkArea, % MonitorNum
            MonitorInfo_Width := Abs(MonitorInfo_Right) - Abs(MonitorInfo_Left)
            MonitorInfo_Height := Abs(MonitorInfo_Bottom) - Abs(MonitorInfo_Top)

            ; Monitor info not found, default to PRIMARY monitor
            if (!MonitorInfo_Width)
            {
                return this._calcDimensionForMonitor(1, InputVal, Axis, IsOffset)
            }

            ; Special Case Processing
            if InputVal is not integer
            {
                FoundPos := RegExMatch(InputVal, "O)^([0-9]{1,})(\%?)$" , DimMatcher)
                Size := DimMatcher.Value(1)
                IsPercent := DimMatcher.Value(2) = "%" ? True : False

                ; User defined a Percent setting, so we need to calculate
                if (True = IsPercent)
                {
                    ; We're calculating SPACIAL values (ie, width/height)
                    AxisComparator := Axis = "x" ? MonitorInfo_Width : MonitorInfo_Height
                    Size := AxisComparator * ( Size / 100)
                }
            }

            ; We want an OFFSET value (ie, x/y coords) based on our Monitor work area
            if (True = IsOffset)
            {
                AxisOffset := Axis = "x" ? MonitorInfo_Left : MonitorInfo_Top
                Size := Size + AxisOffset
            }

            return Round(Size)
        }

        _convertDimensions(dimensions)
        {
            newDims := dimensions.Clone()
        
            newDims.x := this._calcDimensionForMonitor(newDims.monitor, newDims.x, "x", true)
            newDims.y := this._calcDimensionForMonitor(newDims.monitor, newDims.y, "y", true)
            newDims.width := this._calcDimensionForMonitor(newDims.monitor, newDims.width, "x", false)
            newDims.height := this._calcDimensionForMonitor(newDims.monitor, newDims.height, "y", false)

            return newDims
        }

        MoveWindow(hWnd, dimensions)
        {
            newDims := this._convertDimensions(dimensions)

            WinMove, % hWnd,, % newDims.x, % newDims.y, % newDims.width, % newDims.height
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