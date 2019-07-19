#Include <JSON>
#Include <MonitorManager>

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
	class ConfigFromFile extends WindowManager.Functor
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
    class RunConfig extends WindowManager.Functor
	{
        ; TODO - Determine if this is needed to be stored at all
        Settings := ""
        _NumWindows := 0

        Call(self, Config)
        {
            ; TODO - Determine if this is needed to be stored at all
            this.Settings := Config.Settings

            ; Loop over every Config Entry
            For idx, WindowCfg in Config.Entries
            {
                didRun := this.ProcessEntry(WindowCfg, Config.Settings)
                if (true = didRun)
                {
                    this._NumWindows += 1
                }
            }

            if (Config.Settings && True = Config.Settings.ShowFinish)
            {
                MsgBox,, % "WindowManager - Complete", % "Done laying out " . this._NumWindows . " windows."
            }
        }

        ProcessEntry(WindowCfg, Settings)
        {
            UseMonitorNumber := WindowCfg.dimensions && WindowCfg.dimensions.monitor ? WindowCfg.dimensions.monitor : 1
            MonitorForWindow := WindowManager.GetMonitorInfo(UseMonitorNumber, Settings)

            WindowCfg.dimensions.monitor := MonitorForWindow

            if (!MonitorForWindow)
            {
                return false
            }

            identifier := WindowManager.BuildWindow(WindowCfg.identifier, WindowCfg.executable, Settings)

            if (!identifier)
            {
                return false
            }

            WinActivate, % identifier

            try {
                this.ModifyWindow(identifier, WindowCfg.mods)
            } catch err {
                ; Silent Catch
            }

            this.MoveWindow(identifier, WindowCfg.dimensions, MonitorForWindow)

            return true
        }

        ; Move the window to specified Dimensions, after converting to monitor offsets
        MoveWindow(identifier, dimensions, monitor)
        {
            if (!dimensions)
            {
                return
            }

            newDims := WindowManager.ConvertDimensions(dimensions, monitor)

            WinMove, % identifier,, % newDims.x, % newDims.y, % newDims.width, % newDims.height
        }

        ; Modify windows based on predefined keys
        ModifyWindow(identifier, mods)
        {
            if (!mods)
            {
                return
            }

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
                    WinSet, % _WinSet[1], % _WinSet[2], % _WinSet[3]
                }
            }
        }
    }

    class ConvertDimensions extends WindowManager.Functor
    {
        ; Translate Dimensions obj to monitor offset
        Call(self, dimensions, monitor)
        {
            if (!monitor)
            {
                return
            }

            pos := MonitorManager.OffsetForMonitor(dimensions, monitor)
            dims := MonitorManager.AreaForMonitor(dimensions, monitor)
        
            newDims := { x: pos.x, y: pos.y, width: dims.width, height: dims.height }

            if (newDims.x < 0)
            {
                newDims.x += monitor.WorkArea.Right - monitor.WorkArea.Left
            }
            
            if (newDims.y < 0)
            {
                newDims.y += monitor.WorkArea.Bottom
            }

            return newDims
        }
    }

    class GetMonitorInfo extends WindowManager.Functor
    {
        Call(self, MonitorNum, Settings)
        {
            if (!MonitorNum)
            {
                MonitorNum := 1
            }

            MonInfo := MonitorManager.GetMonitorInfo(MonitorNum)

            if (!MonInfo)
            {
                if (1 = MonitorNum)
                {
                    throw Exception("Cannot retrieve Monitor Information, hard failure!")
                }
                ; Default to Monitor 1 if allowed
                else if (Settings && false = Settings.SkipMissingMonitors)
                {
                    return WindowManager.GetMonitorInfo(1, Settings)
                }

                return
            }

            return MonInfo
        }
    }

    class BuildWindow extends WindowManager.Functor
    {
        Call(self, identifier, executable, Settings)
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

            ; IsForced Identifier supplied means to force launch
            ; OR
            ; Identifier doesn't match a window
            if (IsForced or !hWnd)
            {
                Run, % executable,,, PID
                waitIdent := IsForced ? "ahk_pid " . PID : identifier
                TTY := Settings && Settings.TTY_FindWindow ? Settings.TTY_FindWindow : 10
                WinWait, % waitIdent,, % TTY
                if (1 = ErrorLevel)
                {
                    return
                } 
                WinGet, hWnd, id
                identifier := IsForced ? "ahk_id " . hWnd : identifier
            }

            WinWait, % identifier
            return identifier
        }
    }

    class Functor extends JSON.Functor
    {
    }
}