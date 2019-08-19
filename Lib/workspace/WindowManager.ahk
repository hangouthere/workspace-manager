#Include <JSON>
#Include <workspace/MonitorManager>

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

class WindowManager {
    WindowList[] {
        get {
            WinGet, winList, List

            if (0 = winList) {
                return
            }

            hWndList := []
            winInfoList := []

            Loop, % winList {
                val := winList%A_Index%
                hWndList.push(val)
            }

            Loop, % hWndList.Length() {
                curHwnd := hWndList[A_Index]
                winInfo := WindowManager.GetWindowInfo("ahk_id " . curHwnd)
                winInfoList.push(winInfo)
            }

            return winInfoList
        }
    }

    ; Delegate to MonitorManager.GetMonitorInfo, but optionally a fallback to Monitor 1
    _getMonitorInfo(monitorNum, settings) {
        MonInfo := MonitorManager.GetMonitorInfo(monitorNum)

        if (!MonInfo) {
            if (1 = monitorNum) {
                throw Exception("Cannot retrieve Monitor Information, hard failure!")
            }
            ; Default to Monitor 1 if allowed
            else if (settings && false = settings.SkipMissingMonitors) {
                return WindowManager.GetMonitorInfo(1, settings)
            }

            return
        }

        return MonInfo
    }

    processEntry(entry, settings) {
        useMonitorNumber := entry.monitor ? entry.monitor : 1
        monitorForWindow := this._getMonitorInfo(useMonitorNumber, settings)

        if (!monitorForWindow) {
            return false
        }

        proposedIdentifier := this._buildEntryIdentifier(entry)
        identifier := this.buildWindow(proposedIdentifier, entry.executable, entry.forced, settings)

        if (!identifier) {
            return false
        }

        WinActivate, % identifier

        try {
            this.modifyWindow(identifier, entry.mods)
        } catch err {
            ; Silent Catch
        }

        this.moveWindow(identifier, entry.dimensions, monitorForWindow)

        this.sendInputs(entry.inputs)

        return true
    }

    _buildEntryIdentifier(entry) {
        outName := ""

        if (entry.winTitle) {
            outName .= entry.winTitle
        }

        if (entry.winClass) {
            outName .= " ahk_class " . entry.winClass
        }

        if (!outName) {
            if (entry.executable) {
                SplitPath, % entry.executable, nameOnly
                outName := "ahk_exe " . nameOnly
            }
        }

        return Trim(outName)
    }

    ; Move the window to specified Dimensions, after converting to monitor offsets
    moveWindow(identifier, dimensions, monitorInfo) {
        if (!dimensions || dimensions.x = "" || !dimensions.y = "") {
            return
        }

        newDims := WindowManager.ConvertDimensions(dimensions, monitorInfo)

        WinMove, % identifier,, % newDims.x, % newDims.y, % newDims.width, % newDims.height
    }

    sendInputs(Inputs) {
        if (!Inputs.entries) {
            return
        }

        For, idx, val in Inputs.entries {
            ; Send|SendRaw|SendInput||SendPlay|SendEvent

            if (Inputs.mode = 1) {
                Send, % val
            } else if (Inputs.mode = 2) {
                SendRaw, % val
            } else if (Inputs.mode = 3) {
                SendInput, % val
            } else if (Inputs.mode = 4) {
                SendPlay, % val
            } else if (Inputs.mode = 5) {
                SendEvent, % val
            }
        }
    }

    ; Modify windows based on predefined keys
    modifyWindow(identifier, mods) {
        if (!mods) {
            return
        }

        if (0 = mods.minMax) {
            WinRestore, % identifier
        }

        if (1 = mods.minMax) {
            WinMaximize, % identifier
        }

        if (-1 = mods.minMax) {
            WinMinimize, % identifier
        }

        ; Apply custom WinSet values to the window
        if (mods.winSets) {
            For idx, _WinSet in mods.winSets {
                try {
                    cmdVals := StrSplit(_WinSet, ",")
                    WinSet, % Trim(cmdVals[1]), % Trim(cmdVals[2]), % identifier
                } catch err {
                    ; Silent Catch
                }
            }
        }
    }

    buildWindow(identifier, executable, isForced, settings) {
        if (!executable && !isForced) {
            throw Exception("Executable not defined", -1)
        }

        PID := 0
        StringLower, ForceIDentifierCheck, identifier

        if (false = isForced and !identifier) {
            return
        }

        hWnd := (IsForced or !identifier) ? 0 : WinExist(identifier)

        ; IsForced Identifier supplied means to force launch
        ; OR
        ; Identifier doesn't match a window
        if ((IsForced or !hWnd) and executable) {
            Run, % executable,,, PID
            waitIdent := IsForced ? "ahk_pid " . PID : identifier
            TTY := settings && settings.TTY_FindWindow ? settings.TTY_FindWindow : 10
            WinWait, % waitIdent,, % TTY
            if (1 = ErrorLevel) {
                return
            }
            WinGet, hWnd, id
            identifier := IsForced ? "ahk_id " . hWnd : identifier
        }

        if (hWnd) {
            WinWait, % identifier
        }

        return identifier
    }

    class ConvertDimensions extends JSON.Functor {
        ; Translate Dimensions obj to monitor offset
        Call(self, dimensions, monitorInfo) {
            if (!monitorInfo) {
                return
            }

            pos := MonitorManager.MonitorToGlobal(dimensions, monitorInfo)
            dims := MonitorManager.AreaForMonitor(dimensions, monitorInfo)

            newDims := { x: pos.x, y: pos.y, width: dims.width, height: dims.height }

            if (newDims.x < 0) {
                newDims.x += monitorInfo.WorkArea.Right - (monitorInfo.Offset.Width - monitorInfo.WorkArea.Width)
            }

            if (newDims.y < 0) {
                newDims.y += monitorInfo.WorkArea.Bottom - (monitorInfo.Offset.Height - monitorInfo.WorkArea.Height)
            }

            return newDims
        }
    }

    class GetWindowDimensions extends JSON.Functor {
        Call(self, winTitle := "A") {
            WinGetPos, x, y, w, h, % winTitle

            return {x:x, y:y, width: w, height: h}
        }
    }

    class GetWindowInfo extends JSON.Functor {
        Call(self, winTitle := "A") {
            WinGetTitle, t1, % winTitle
            WinGetClass, t2, % winTitle
            WinGet, t3, ProcessPath, % winTitle
            WinGet, t4, ProcessName, % winTitle
            WinGet, t5, ID, % winTitle
            WinGet, t6, PID, % winTitle
            WinGet, t7, MinMax, % winTitle

            return {winTitle: Trim(t1)
                , winClass: Trim(t2)
                , executablePath: t3
                , executable: t4
                , hWnd: t5
                , pid: t6
                , mods: { minMax: t7} }
        }
    }
}