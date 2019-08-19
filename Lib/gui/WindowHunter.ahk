#Include <JSON>
#Include <workspace/Util>
#Include <workspace/WindowManager>
#Include <workspace/MonitorManager>

BASIC_HEIGHT := 250
ADV_HEIGHT := 40

class WindowHunter {
    _showAll := false
    _currMonitor := 1
    _monCount := 0
    _onSelect := 0
    _winList := 0
    _selWinIdx := 0
    _selWinInfo := 0

    __New(onSelectCallback := 0) {
        this._monCount := MonitorManager.MonitorCount
        this._onSelect := onSelectCallback
    }

    Show() {
        this._drawGui()

        this.refreshUI()
    }

    _drawGui() {
        this.gui := new GuiWrapper("windowHunter", "-MinimizeBox -MaximizeBox")

        gui := this.gui

        gui.editFont("s12")
        gui.addControl("_", "Edit", "x104 y8 w44 h26 +ReadOnly", "1")
        this._guiMonSel := gui.addControl("_", "UpDown", "x-24 y-24 w0 h21", "1", this.refreshUI.bind(this))
        gui.editFont()
        gui.editFont("s18")
        gui.addControl("_", "Text", "x8 y8 +0x200", "Monitor")
        gui.editFont()
        gui.addControl("_", "Button", "x400 y220 w105 h33", "Select Window", this._onClickSelWindow.bind(this))
        gui.addControl("_", "Text", "x15 y205 +0x200", "Num Windows:")
        gui.addControl("_", "Button", "x280 y8 w30 h23", "R", this.refreshUI.bind(this))
        this._guiAllMon := gui.addControl("_", "CheckBox", "x160 y8 w120 h23", "Show All Monitors", this.refreshUI.bind(this))
        this._guiWinList := gui.addControl("_", "ListBox", "x8 y40 w300 h160 AltSubmit",, this._onWindowSelected.bind(this))
        this._guiNumWin := gui.addControl("_", "Text", "x92 y205 w50 +0x200", "0")

        gui.addControl("_", "Tab3", "x315 y8 w330 h200", "General|Position|Monitor")
        gui.editTab(1)
        this._guiGenInfo := gui.addControl("_", "Edit", "x320 y30 w315 h170 +ReadOnly +Multi")
        gui.editTab(2)
        this._guiDimInfo := gui.addControl("_", "Edit", "x320 y30 w315 h170 +ReadOnly +Multi")
        gui.editTab(3)
        this._guiMonInfo := gui.addControl("_", "Edit", "x320 y30 w315 h170 +ReadOnly +Multi")
        gui.editTab()

        gui.Show("w650 h250", "Window Hunter by nfgCodex")
    }

    refreshUI() {
        if (1 = this._monCount) {
            this._guiAllMon.Set(1, 1, 0, 0)
            this._guiAllMon.updateControl("Disable")
        } else {
            this._guiAllMon.updateControl("Enable")
        }

        if (1 = this._guiAllMon.get()) {
            this._guiMonSel.updateControl("Disable")
        } else {
            this._guiMonSel.updateControl("Enable")

            ; Only allow a range of monitor count on the UPDOWN component
            this._guiMonSel.updateControl("+Range1-" . this._monCount)
        }
        
        this._updateWindowList()
        this._setWinSize()
    }

    _updateWindowList() {
        this._winList := []
        curWinList := WindowManager.WindowList
        winNamesList := "|"
        _count := 0

        For, idx, winInfo in curWinList {
            ; Tack on extra meta info
            winInfo.dimensions := WindowManager.GetWindowDimensions("ahk_id " . winInfo.hwnd)
            winInfo.monitorInfo := MonitorManager.FindMonitorForOffset(winInfo.dimensions)

            winInfo.dimensions := MonitorManager.GlobalToMonitor(winInfo.dimensions, winInfo.monitorInfo)

            if (winInfo.monitorInfo) {
                winInfo.monitor := winInfo.monitorInfo.index
            }

            foundTitleName := StrLen(winInfo.winTitle) > 50 ? SubStr(winInfo.winTitle, 1, 47) . "..." : winInfo.winTitle
            foundTitleName := foundTitleName ? foundTitleName : "?"
            foundTitleName := StrReplace(foundTitleName, "|", "\|")

            ; Only add if "Show All Monitors" is checked, 
            ; or the mon number matches the selected in UI
            curMon := this._guiMonSel.get()
            shouldAdd := this._guiAllMon.get() || (curMon = winInfo.monitorInfo.index)

            if (shouldAdd && foundTitleName) {
                winNamesList .= foundTitleName . "|"
                this._winList.push(winInfo)
                _count += 1
            }
        }

        winNamesList := SubStr(winNamesList, 1, -1)

        this._guiWinList.Set(winNamesList, 1, 0, 0) ; Set List
        this._guiNumWin.Set(_count, 1, 0, 0) ; Set count
        this._guiWinList.Set(1, 1) ; Set choice, and trigger!
    }

    ; Sets size to show/hide bottom select button based on init option
    _setWinSize() {
        global BASIC_HEIGHT
        global ADV_HEIGHT

        isOpen := this._onSelect
        newHeight := isOpen ? BASIC_HEIGHT + ADV_HEIGHT : BASIC_HEIGHT

        WinMove, % this.gui.ident,,,,, % newHeight
    }

    ; Handle a callback once a window is selected
    ; Also closes window
    _onClickSelWindow() {
        this.gui.close()

        if (this._onSelect) {
            ; exec callback with selected win info
            this._onSelect.Call(this._selWinInfo)
        }
    }

    ; Callback for when a window is selected in the listbox
    _onWindowSelected(idx) {
        this._selWinIdx := idx
        this._selWinInfo := this._winList[idx]

        this._updateWindowUI(this._selWinInfo)
    }

    ; Updates portions of the UI based on window information
    _updateWindowUI(winInfo) {
        cloneInfo := Util.Array_DeepClone(winInfo)
        dim := cloneInfo.delete("dimensions")
        mon := cloneInfo.delete("monitorInfo")

        if (!mon) {
            mon := " Not Available"
        }

        this._guiGenInfo.Set(SubStr(JSON.Dump(cloneInfo,, 1), 3, -1), 1, 0, 0)
        this._guiDimInfo.Set(SubStr(JSON.Dump(dim,, 1), 3, -1), 1, 0, 0)
        this._guiMonInfo.Set(SubStr(JSON.Dump(mon,, 4), 3, -1), 1, 0, 0)
    }
}