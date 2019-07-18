#Include <JSON>

/**
 * Lib: WindowManager.ahk
 *     Manage Windows with AutoLaunch and other features (TBD).
 * Version:
 *     v1.0.0 [updated 07/18/2019 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include WindowManager.ahk or copy into a function library folder and then
 *     use #Include <WindowManager>
 * Links:
 *     GitHub:     - https://bitbucket.org/nerdfoundrygaming/ahk.windowmanager
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
            try {	
			    FileObj := FileOpen(FileName, "r")
            } catch e {
				throw Exception("Can't open " . FileName . " for reading.", -1)
            }
			
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
        Settings := ""
        _NumWindows := 0

        Call(self, Config)
        {
            OutputDebug, -------------------------------------------

            this.Settings := Config.Settings

            ; Loop over every Config Entry
            For idx, WindowCfg in Config.Entries
            {
                OutputDebug, % JSON.Dump(WindowCfg)
                identifier := this.DetectWindow(WindowCfg.identifier, WindowCfg.executable)

                if (!identifier)
                {
                    Continue
                }

                WinActivate, % identifier
                try {
                    this.ModifyWindow(identifier, WindowCfg.mods)
                } catch err {
                    ; Silent Catch
                }
                this.MoveWindow(identifier, WindowCfg.dimensions)
                this._NumWindows += 1
            }

            if (Config.Settings && True = Config.Settings.ShowFinish)
            {
                MsgBox,, % "WindowManager - Complete", % "Done laying out " . this._NumWindows . " windows."
            }
        }

        DetectWindow(identifier, executable)
        {
            if (!executable)
            {
                throw Exception("Executable not defined", -1)
            }

            PID := 0
            StringLower, ForceIDentifierCheck, identifier
            IsForcedFull := "force" = SubStr(ForceIDentifierCheck, 1, 5)
            IsForcedShort := "F|" = SubStr(ForceIDentifierCheck, 1, 2)
            IsForced := IsForcedFull || IsForcedShort

            ; strip "force " || "F|" from the identifier
            if (True = IsForced)
            {
                identifier := IsForcedFull ? SubStr(ForceIDentifierCheck, 7) ? SubStr(ForceIDentifierCheck, 3)
            }
            else if (!identifier)
            {
                return
            }

            hWnd := (IsForced or !identifier) ? 0 : WinExist(identifier)

            OutputDebug, % "IsForced: " . IsForced
            OutputDebug, % "hWnd: " . hWnd

            ; IsForced Identifier supplied means to force launch
            ; OR
            ; Identifier doesn't match a window
            if (IsForced or !hWnd)
            {
                OutputDebug, % "Not Running (or forced?), Executing: " . executable
                Run, % executable,,, PID
                OutputDebug, % "Running PID: " . PID
                waitIdent := IsForced ? "ahk_pid " . PID : identifier
                TTY := (this.Settings && this.Settings.TTY_FindWindow) ? this.Settings.TTY_FindWindow : 10
                OutputDebug, % "WaitIdent: " . waitIdent . " for " . TTY . " seconds"
                WinWait, % waitIdent,, % TTY
                if (1 = ErrorLevel)
                {
                    OutputDebug, Timed out looking for WaitIdent
                    return
                } 
                else
                {
                    OutputDebug, We have a window
                }
                WinGet, hWnd, id
                OutputDebug, % "HWND Found: " . hWnd
                identifier := IsForced ? "ahk_id " . hWnd : identifier
            }

            WinWait, % identifier
            OutputDebug, % "Using ID: " . identifier 
            return identifier
        }

        ; Calculate percentages, negative offsets, and account for toolbars taking real-estate
        _calcDimensionForMonitor(MonitorNum, InputVal, Axis := "x", IsOffset := True)
        {
            Size := InputVal

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
                AxisEndingOffset := Axis = "x" ? (MonitorInfo_Width + MonitorInfo_Left) : (MonitorInfo_Height + MonitorInfo_Top)
                FinalOffset := Size >= 0 ? AxisOffset : AxisEndingOffset
                Size := Size + FinalOffset
            }

            return Round(Size)
        }

        ; Translate Dimensions obj to monitor offset
        _convertDimensions(dimensions)
        {
            newDims := dimensions.Clone()
        
            newDims.x := this._calcDimensionForMonitor(newDims.monitor, newDims.x, "x", true)
            newDims.y := this._calcDimensionForMonitor(newDims.monitor, newDims.y, "y", true)
            newDims.width := this._calcDimensionForMonitor(newDims.monitor, newDims.width, "x", false)
            newDims.height := this._calcDimensionForMonitor(newDims.monitor, newDims.height, "y", false)

            return newDims
        }

        ; Move the window to specified Dimensions, after converting to monitor offsets
        MoveWindow(identifier, dimensions)
        {
            if (!dimensions)
            {
                return
            }

            newDims := this._convertDimensions(dimensions)

            WinMove, % identifier,, % newDims.x, % newDims.y, % newDims.width, % newDims.height
        }

        ; Modify windows based on predefined keys
        ModifyWindow(identifier, mods)
        {
            if (!mods)
            {
                return
            }

            OutputDebug, % "Mods to apply: " . JSON.Dump(mods)

            if (True = mods.restore)
            {
                WinRestore, % identifier
            }

            if (True = mods.maximize)
            {
                WinMaximize, % identifier
            }

            if (True = mods.minimize)
            {
                WinMinimize, % identifier
            }

            if (mods.WinSet)
            {
                For idx, _WinSet in mods.WinSet
                {
                    OutputDebug, % JSON.Dump(_WinSet)
                    WinSet, % _WinSet[1], % _WinSet[2], % _WinSet[3]
                }
            }
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