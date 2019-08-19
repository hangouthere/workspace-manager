#Include <JSON>
#Include <GuiWrapper>
#Include <workspace/Util>
#Include <workspace/MonitorManager>
#Include <workspace/MouseManager>
#Include <workspace/WindowManager>
#Include <workspace/WorkspaceManager>
#Include <gui/MgrMenu>
#Include <gui/MgrTabEntries>
#Include <gui/MgrTabSettings>
#Include <gui/WindowHunter>

ORIG_WIN_SIZE := 0
FULL_WIN_SIZE := 250
NAME_UNSAVED := "[Unsaved].json"

class ManagerGUI {
    mainMenu := 0

    _wsm := 0

    ; Self Gui
    _isOpen := false

    ; Children
    _tabEntries := 0
    _tabSettings := 0

    _wsClean := true

    IsDirty[] {
        get {
            return !this._wsClean || this._tabEntries.isDirty
        }
    }

    __New(FileName) {
        this._wsm := new WorkspaceManager(FileName)

        this.loadConfig(FileName)
    }

    loadConfig(FileName) {
        this._wsm.loadConfig(FileName)

        if (this._tabEntries) {
            this._tabEntries.reset()
        }
    }

    Show() {
        global ORIG_WIN_SIZE
        global APP_NAME
        global APP_VERSION

        this._drawGui()
        this.refreshUI(1)

        this.gui.Show("w630 h340", APP_NAME . " by nfgCodex - " . APP_VERSION)
        WinWait % this.gui.ident
        WinGetPos,,,, ORIG_WIN_SIZE
    }

    _drawGui() {
        this.gui := new GuiWrapper(, "-MinimizeBox -MaximizeBox")

        this.gui.addControl("btnAdv", "Button", "x553 y0 w75 h22", "Advanced >", this.toggleAdv.Bind(this))

        ;; Tab System
        this.gui.addControl("_", "Tab3", "x0 y0 w630 h570 AltSubmit", "Entries|Settings", this.tabChanged.Bind(this))
        this._tabEntries := new MgrTabEntries()
        this._tabSettings := new MgrTabSettings()
        this._tabEntries.AttachToGui(this.gui, this, this._wsm)
        this._tabSettings.AttachToGui(this.gui, this, this._wsm)
        this.gui.EditTab()

        ;; StatusBar Setup
        this.gui.addControl("_", "StatusBar",, "Please Load a Workspace...")
        SB_SetParts(250, 200, 100)  ; Workspace Name | Entries | Monitors (implicit)

        ;; Menu Setup
        this.mainMenu := new MgrMenu(this.gui, this, this._wsm)

        this._guiBtnAdv := this.gui.ctrls["btnAdv"]
        this._guiBtnDel := this.gui.ctrls["btnDel"]
    }

    refreshUI(selIdx := 0) {
        this._tabEntries.refresh(selIdx)
        this._refreshSettingsUI()
        this.refreshUIStatus()
    }

    refreshUIStatus() {
        this._refreshStatusBar()
        this._refreshMenuStatus()
    }

    _refreshSettingsUI() {
        settingsKeys := ["Settings.TTY_FindWindow"
            , "Settings.ShowFinish"
            , "Settings.SkipMissingMonitors"
            , "Settings.WinSearchMode"
            , "Settings.SearchHiddenWindows"]

        For idx, key in settingsKeys {
            builtKey := StrSplit(key, ".")
            ctrl := this.gui.ctrls[key]
            val := this._wsm.config[builtKey*]
            ctrl.Set(val, 1, 0, 0)
        }
    }

    _refreshStatusBar() {
        wsName := this._wsm.name
        entriesNum := this._wsm.config.Entries.Length()
        monNum := MonitorManager.MonitorCount
        wsState := this._wsClean ? "Clean" : "Dirty"
        entryState := this._tabEntries.isDirty ? "Dirty" : "Clean"

        SB_SetText(" Workspace: " . wsName, 1)
        SB_SetText("`tWS: " . wsState . ", Entry: " . entryState, 2)
        SB_SetText("`tEntries: " . entriesNum, 3)
        SB_SetText("`tMonitors: " . monNum, 4)
    }

    _refreshMenuStatus() {
        ws := this.gui.Menus["Workspace"]
        entry := this.gui.Menus["Entries"]

        ws.toggle("&New", !this.isDirty)
        ws.toggle("&Run", !this.isDirty)
        entry.toggle("Add &Blank", !this.isDirty)
        entry.toggle("&Hunt for a Window...", !this.isDirty)

        btnLbl := true = this.isDirty ? "Reset Entry" : "Delete Entry"
        this._guiBtnDel.Set(btnLbl, 1, 0, 0)
    }

    saveWorkspace(saveAs := false) {
        global NAME_UNSAVED
        global APP_NAME

        if (!this._wsm.config.entries.length()) {
            return
        }

        fileName := 0

        if (true = saveAs || NAME_UNSAVED = this._wsm.fileName) {
            FileSelectFile, fileName, 16, , Select file to Save Workspace Configuration, WS JSON Config Files (*.json)

            if (!fileName) {
                return
            }
        }

        this._wsm.saveConfig(fileName)

        this._wsClean := true

        this.refreshUIStatus()

        MsgBox, % 0x2000 | 0x40000, % APP_NAME, Saved Workspace!
    }

    toggleAdv() {
        global ORIG_WIN_SIZE
        global FULL_WIN_SIZE
        this._isOpen := !this._isOpen
        lbl := this._isOpen ? "< Basic" : "Advanced >"
        newHeight := this._isOpen ? ORIG_WIN_SIZE + FULL_WIN_SIZE : ORIG_WIN_SIZE
        hwnd := this.gui.hwnd

        this._guiBtnAdv.Set(lbl, 1, 0, 0)

        WinMove, % "ahk_id " . hwnd,,,,, % newHeight

        this.refreshUIStatus()
    }

    onLeftMouseButton() {
        if (false = this._tabEntries.isTargetingWindow) {
            return
        }

        this._tabEntries.windowTargeted()
    }

    ; Fired for every Setting updated in the UI
    updateSettings(setting, value) {
        builtKey := StrSplit(setting, ".")
        prevVal := this._wsm.config[builtKey*]

        if (not prevVal = value) {
            this._wsm.config[builtKey*] := value
            this._wsClean := false
            this.refreshUIStatus()
        }
    }

    tabChanged(tabIdx) {
        if (2 != tabIdx) {
            this._guiBtnAdv.updateControl("Enable")
            return
        }

        this._guiBtnAdv.updateControl("Disable")
        this._isOpen := true
        this.toggleAdv()
    }
}