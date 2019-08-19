#Include <workspace/Util>
#Include <workspace/MouseManager>
#Include <workspace/WindowManager>
#Include <gui/WindowHunter>
#Include <GuiWrapper>

class MgrTabEntries {
    _host := 0
    _wsm := 0
    _gui := 0

    ; State
    _currEntryIdx := 0
    _currEntry := 0
    _isClean := true
    _isNewEntry := false
    _currInput := 0
    _currWinSet := 0
    _targetingWindowType := 0

    ; GUI members
    _guiLstEntries := 0
    _guiLstInputs := 0
    _guiExe := 0

    isDirty[] {
        get {
            return !this._isClean
        }
    }

    isTargetingWindow[] {
        get {
            return this._targetingWindowType != 0
        }
    }

    AttachToGui(gui, host, wsm) {
        this._gui := gui
        this._host := host
        this._wsm := wsm

        prxyUpd := this._onEntryChanged.Bind(this)
        prxyReorder := this._reorderEntry.Bind(this)
        prxyFindWin := this._winTarget.Bind(this)
        prxyReorderInp := this._reorderInput.Bind(this)

        gui.EditTab(1)

        ;;;;;; Entries List ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.addControl("_", "Text", "x8 y5 w120 h23 +0x200", "Entries")
        this._guiLstEntries := gui.addControl("lstEntries", "ListBox", "x8 y29 w120 h263 AltSubmit",, this._entrySelected.Bind(this))
        gui.addControl("_", "Button", "x28 y290 w23 h23", "Up", Util.DoubleBind(prxyReorder, -1))
        gui.addControl("_", "Button", "x78 y290 w23 h23", "Dn", Util.DoubleBind(prxyReorder, 1))

        ;;;;;; Entry Setup ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.EditFont("s18")
        gui.addControl("_", "Text", "x144 y29 w130 h30 +0x200", "Entry Setup")
        gui.EditFont()

        ;;;;;;;;;; Window Info ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.addControl("_", "GroupBox", "x144 y61 w474 h103", "Window Information")
        gui.addControl("_", "Text", "x160 y88 +0x200", "Window Title Search")
        gui.addControl("_", "Text", "x160 y112 +0x200", "Window Class (ahk_class)")
        gui.addControl("_", "Text", "x160 y136 +0x200", "Executable")
        gui.addControl("_", "Button", "x584 y132 w23 h23", "...", this._findExe.Bind(this))
        gui.addControl("entry_forced", "CheckBox", "x525 y88", "Force Launch", Util.DoubleBind(prxyUpd, "forced"))
        gui.addControl("entry_winTitle", "Edit", "x296 y85 w175 h21",, Util.DoubleBind(prxyUpd, "winTitle"))
        gui.addControl("entry_winClass", "Edit", "x296 y109 w175 h21",, Util.DoubleBind(prxyUpd, "winClass"))
        this._guiExe := gui.addControl("entry_executable", "Edit", "x296 y133 w250 h21",, Util.DoubleBind(prxyUpd, "executable"))

        btnFind1 := gui.addControl("_", "Button", "x475 y84 w30 h23 +64", "Find", Util.DoubleBind(prxyFindWin, "winTitle"))
        btnFind2 := gui.addControl("_", "Button", "x475 y108 w30 h23 +64", "Find", Util.DoubleBind(prxyFindWin, "winClass"))
        btnFind3 := gui.addControl("_", "Button", "x550 y132 w30 h23 +64", "Find", Util.DoubleBind(prxyFindWin, "executablePath"))

        ;;;;;;;;;; Position Info ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.addControl("_", "GroupBox", "x144 y173 w193 h104", "Position Information")
        gui.addControl("_", "Text", "x152 y192 +0x200", "Monitor Number")
        gui.addControl("_", "Text", "x160 y224 +0x200", "X")
        gui.addControl("_", "Text", "x160 y248 +0x200", "Y")
        gui.addControl("_", "Text", "x240 y224 +0x200", "Width")
        gui.addControl("_", "Text", "x240 y248 +0x200", "Height")
        gui.addControl("_", "Edit", "x248 y189 w50 h21 Number")
        gui.addControl("entry_monitor", "UpDown", "x280 y189 Range1-10",, Util.DoubleBind(prxyUpd, "monitor"))
        gui.addControl("entry_dimensions.x", "Edit", "x184 y221 w45 h21",, Util.DoubleBind(prxyUpd, "dimensions.x"))
        gui.addControl("entry_dimensions.y", "Edit", "x184 y245 w45 h21",, Util.DoubleBind(prxyUpd, "dimensions.y"))
        gui.addControl("entry_dimensions.width", "Edit", "x280 y221 w45 h21",, Util.DoubleBind(prxyUpd, "dimensions.width"))
        gui.addControl("entry_dimensions.height", "Edit", "x280 y245 w45 h21",, Util.DoubleBind(prxyUpd, "dimensions.height"))

        ;;;;;;;;;; Misc Info ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.addControl("_", "GroupBox", "x352 y173 w266 h103", "Misc")
        gui.addControl("_", "Text", "x368 y192 +0x200", "Entry Title")
        gui.addControl("entry_title", "Edit", "x432 y189 w173 h21",, Util.DoubleBind(prxyUpd, "title"))
        gui.addControl("_", "Text", "x368 y224 +0x200", "Win Mode")
        gui.addControl("entry_mods.minMax", "DropDownList", "x432 y221 w80 AltSubmit", "Minimized|Restored||Maximized", Util.DoubleBind(prxyUpd, "mods.minMax"))

        gui.addControl("btnDel", "Button", "x435 y285 w80 h23", "Delete Entry", this._delOrResetEntry.Bind(this))
        gui.addControl("_", "Button", "x525 y285 w80 h23", "Save Entry", this.saveEntry.Bind(this))

        ;;;;;;;;;; Advanced Info ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        gui.addControl("_", "GroupBox", "x10 y325 w330 h230", "Inputs")
        gui.addControl("_", "Text", "x20 y354 +0x200", "Input Mode")
        gui.addControl("_", "Text", "x20 y375 +0x200", "Inputs")
        gui.addControl("entry_inputs.mode", "DropDownList", "x110 y350 w80 AltSubmit", "Send|SendRaw|SendInput||SendPlay|SendEvent", Util.DoubleBind(prxyUpd, "inputs.mode"))
        this._guiLstInputs := gui.addControl("_", "ListBox", "x110 y375 w215 h160 AltSubmit",, this.selInput.Bind(this))
        gui.addControl("_", "Button", "x25 y500 w30 h23", "+", this._addInput.Bind(this))
        gui.addControl("_", "Button", "x60 y500 w30 h23", "-", this._delInput.Bind(this))
        gui.addControl("_", "Button", "x70 y420 w30 h23", "Up", Util.DoubleBind(prxyReorderInp, -1))
        gui.addControl("_", "Button", "x70 y460 w30 h23", "Dn", Util.DoubleBind(prxyReorderInp, 1))

        gui.addControl("_", "GroupBox", "x350 y325 w275 h230", "WinSets")
        this._guiLstWinSets := gui.addControl("_", "ListBox", "x360 y355 w255 h160 AltSubmit",, this.selWinSet.Bind(this))
        gui.addControl("_", "Button", "x375 y523 w30 h23", "+", this._addWinSet.Bind(this))
        gui.addControl("_", "Button", "x410 y523 w30 h23", "-", this._delWinSet.Bind(this))

        try {
            ; Set Icons to buttons
            btnFind1.addGraphicToControl("crosshair.ico")
            btnFind2.addGraphicToControl("crosshair.ico")
            btnFind3.addGraphicToControl("crosshair.ico")
        } catch err {
            ; Silent fail if user doesn't have icon
        }
    }

    reset() {
        this._currEntry := 0
        this._currEntryIdx := 0
    }

    refresh(selIdx := 0) {
        this._refreshEntriesListUI(selIdx)
        this._refreshEntryUI()
        this._refreshInputsUI()
        this._refreshWinSetsUI()
    }

    saveEntry() {
        global APP_NAME

        if (!this._currEntry.forced && !this._currEntry.winTitle && !this._currEntry.winClass) {
            MsgBox,, % APP_NAME, You need to supply at least a winTitle or winClass, or Force the entry!
            return
        }

        if (!this._currEntry.forced && !this._currEntry.executable) {
            MsgBox,, % APP_NAME, You must supply an Executable if the Window doesn't exist, or Force the entry!
            return
        }

        this._wsm.replaceEntryAt(this._currEntryIdx, this._currEntry)
        this._host.saveWorkspace()
        this._host.refreshUI()
        this._isClean := true
        this._isNewEntry := false
        this._host.refreshUIStatus()
    }

    deleteEntry(forced := false) {
        global APP_NAME

        if (!forced) {
            isOk := GuiWrapper.Confirm("Are you sure you want to delete this entry?", APP_NAME)

            if (!isOk) {
                return
            }
        }

        this._wsm.removeEntryAt(this._currEntryIdx)
        this._currEntry := 0
        this._currEntryIdx := 0

        this._isClean := true
        this._host.refreshUI(1)

        if (!forced) {
            this._host.saveWorkspace()
        }
    }

    addDirtyEntry(entry) {
        ; Add the entry and refresh UI
        idx := this._wsm.addEntry(entry)
        this._currEntryIdx := 0
        this._currEntry := entry
        this._host.refreshUI(idx)
        ; Since refresh will cause the list select, and that will
        ; trigger a forced clean entry, we want to re-force dirty
        this._isClean := false
        this._isNewEntry := true
        this._host.refreshUIStatus()
    }

    windowHunt() {
        hunter := new WindowHunter(this._onWindowHunted.bind(this))
        hunter.Show()
    }

    windowTargeted() {
        this._onWinTargeted()
    }

    ;;; PRIVATE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    _refreshEntriesListUI(selIdx) {
        idxChosen := selIdx ? selIdx : this._currEntryIdx

        ; Set Entry Names in list
        this._guiLstEntries.Set(this._wsm.entryListNames, 1, 0, 0)
        ; Default first selection, triggers MgrTabEntries._entrySelected
        this._guiLstEntries.Set(idxChosen, 1, 0, 1)
    }

    _refreshInputsUI() {
        inputVals := "|"

        For, idx, _input in this._currEntry.inputs.entries {
            inputVals .= _input . "|"
        }

        this._guiLstInputs.Set(inputVals, 1, 0, 0)
        this._guiLstInputs.Set(this._currInput, 1, 0, 0)
    }

    _refreshWinSetsUI() {
        inputVals := "|"

        For, idx, _input in this._currEntry.mods.winSets {
            inputVals .= _input . "|"
        }

        this._guiLstWinSets.Set(inputVals, 1, 0, 0)
        this._guiLstWinSets.Set(this._currWinSet, 1, 0, 0)
    }

    _refreshEntryUI() {
        entryKeys := [ "title"
            , "winTitle"
            , "winClass"
            , "forced"
            , "executable"
            , "monitor"
            , "dimensions.x"
            , "dimensions.y"
            , "dimensions.width"
            , "dimensions.height"
            , "mods.minMax"
            , "inputs.mode" ]

        For idx, key in entryKeys {
            entryKey := "entry_" . key
            ctrl := this._gui.ctrls[entryKey]
            builtKey := StrSplit(key, ".")
            val := this._currEntry[builtKey*]

            ; Offset, see _onEntryChanged()
            if (key = "mods.minMax") {
                val += 2
            }
            ; Choose instead of set label
            if (key = "forced") {
                val := (val = true)
            }

            ctrl.Set(val, 1, 0, 0)
        }
    }

    ; Fired on selection change of Entry List
    _entrySelected(idx) {
        global APP_NAME

        ; Skip if same idx selected
        if (!idx || idx = this._currEntryIdx) {
            return
        }

        if (false = this._isClean) {
            doChange := GuiWrapper.Confirm("The current entry will lose unsaved data, are you sure?", APP_NAME)

            if (false = doChange) {
                ; Make sure the previous entry is still selected, but doesn't affect anything
                this._guiLstEntries.Set(this._currEntryIdx, 1, 0, 0)
                return
            }
            ; This was a new entry and left unsaved, so we'll remove it from the list
            else if (true = this._isNewEntry) {
                this.deleteEntry(true)
            }
        }

        ; Clone Entry for Editing
        entry := this._wsm.config.Entries[idx]
        entry := Util.Array_DeepClone(entry)

        this._currEntry := entry
        this._currEntryIdx := idx
        this._isClean := true
        this._isNewEntry := false

        this._host.refreshUI()
    }

    ; Fired for every part of an Entry updated in the UI
    _onEntryChanged(prop, value) {
        builtKey := StrSplit(prop, ".")
        prevVal := this._currEntry[builtKey*]

        ; MinMax: -1 min, 0 restored (desired), 1 max
        ; UI: 1 min, 2 restored, 3 max
        ; So we offset by -2 to match proper minMax values
        if ("mods.minMax" = prop) {
            value -= 2
        }

        if (not prevVal = value) {
            this._currEntry[builtKey*] := value
            this._isClean := false
            this._host.refreshUIStatus()
        }
    }

    _onWindowHunted(winInfo) {
        ; Clean up winInfo to match expected config parse
        winInfo.executable := winInfo.executablePath

        this.addDirtyEntry(winInfo)
    }

    _delOrResetEntry() {
        if (false = this._isNewEntry && true = this.isDirty) {
            curIdx := this._currEntryIdx
            this._currEntryIdx := 0
            this._isClean := true ; set for entry item selection to work properly
            this._host.refreshUI(curIdx)
        } else {
            this.deleteEntry()
        }
    }

    _findExe() {
        FileSelectFile, fileName, 32,, Select file to Execute

        if (!fileName) {
            return
        }

        this._guiExe.Set(fileName, 1)
    }

    _reorderEntry(direction) {
        nextIdx := this._currEntryIdx + direction
        max := this._wsm.config.Entries.Length()

        if (nextIdx > max) {
            nextIdx := 1
            this._wsm.removeEntryAt(this._currEntryIdx)
            this._wsm.addEntry(this._currEntry, 1)
        } else if (nextIdx < 1) {
            nextIdx := max
            this._wsm.removeEntryAt(this._currEntryIdx)
            this._wsm.addEntry(this._currEntry, max)
        } else {
            this._wsm.swapEntriesAt(this._currEntryIdx, nextIdx)
        }

        this._host.refreshUI(nextIdx)
        this._host._wsClean := false
        this._host.refreshUIStatus()
    }

    _winTarget(findType) {
        global APP_NAME

        MsgBox,, % APP_NAME, % "Click a window to grab the " . findType ".`n`nIf you have problems targeting a window, try out the ""Window Hunter"" in the ""Entries"" menu."

        this._targetingWindowType := findType
        MouseManager.SetCursor(MouseManager.CursorTypes.NSEW_SMALL)
    }

    _onWinTargeted() {
        global APP_NAME

        MouseManager.ResetCursor()

        if (this._targetingWindowType) {
            mouseInfo := MouseManager.MouseInfo

            if (!mouseInfo) {
                return
            }

            winInfo := WindowManager.GetWindowInfo("ahk_id" . mouseInfo.hwnd)

            if (winInfo) {
                guiEntryName := "entry_" . this._targetingWindowType

                ; Override for executable as we're targeting the path that's found from WindowManager
                if ("executablePath" = this._targetingWindowType) {
                    guiEntryName := "entry_executable"
                }

                if (winInfo[this._targetingWindowType]) {
                    ; Update UI with Info
                    this._gui.ctrls[guiEntryName].set(winInfo[this._targetingWindowType], 1, 0, 0)
                } else {
                    MsgBox,, % APP_NAME, % "The window you selected does not have a valid " . this._targetingWindowType . "`n`nPlease try again and select a different window."
                }
            }

            Sleep, 100
            this._gui.focus()
        }

        this._targetingWindowType := false
    }

    _addInput() {
        this._addUpdateInput()
    }

    _delInput() {
        global APP_NAME

        if (!this._currInput) {
            return
        }

        doChange := GuiWrapper.Confirm("Are you sure you want to delete this Input?", APP_NAME)

        if (!doChange) {
            return
        }

        this._currEntry.inputs.entries.removeAt(this._currInput)

        this._refreshInputsUI()
        this._isClean := false
        this._host.refreshUIStatus()
    }

    _reorderInput(direction) {
        if (!this._currInput) {
            return
        }

        entres := this._currEntry.inputs.entries

        nextIdx := this._currInput + direction
        max := this._currEntry.inputs.entries.Length()

        if (nextIdx > max) {
            nextIdx := 1
            curVal := this._currEntry.inputs.entries.removeAt(this._currInput)
            this._currEntry.inputs.entries.insertAt(1, curVal)
        } else if (nextIdx < 1) {
            nextIdx := max
            curVal := this._currEntry.inputs.entries.removeAt(this._currInput)
            this._currEntry.inputs.entries.insertAt(max, curVal)
        } else {
            oldA := this._currEntry.inputs.entries[this._currInput]
            oldB := this._currEntry.inputs.entries[nextIdx]

            this._currEntry.inputs.entries[this._currInput] := oldB
            this._currEntry.inputs.entries[nextIdx] := oldA
        }

        this._currInput := nextIdx

        this._refreshInputsUI()
        this._isClean := false
        this._host.refreshUIStatus()
    }

    selInput(idx) {
        isDblClick := A_GuiEvent == "DoubleClick"
        this._currInput := idx

        if (!isDblClick) {
            return
        }

        this._addUpdateInput(true)
    }

    _addUpdateInput(prevEntry := false) {
        titlePrefix := prevEntry ? "Edit" : "Add"
        prevVal := prevEntry && this._currInput ? this._currEntry.inputs.entries[this._currInput] : ""
        InputBox, newEntry, % titlePrefix . " Input", % "Please enter an input line.`n`nExample: ""^t"" - <CTRL+T>, to open a new tab`n`nSee README for more info.",,,,,,,, % prevVal

        if (!newEntry) {
            return
        }

        if (prevEntry && this._currInput) {
          this._currEntry.inputs.entries.removeAt(this._currInput)
          this._currEntry.inputs.entries.insertAt(this._currInput, newEntry)
        } else {
          this._currEntry.inputs.entries.push(newEntry)
        }

        this._refreshInputsUI()
        this._isClean := false
        this._host.refreshUIStatus()
    }

    _addWinSet() {
        this._addUpdateWinSet()
    }

    _delWinSet() {
        global APP_NAME

        if (!this._currWinSet) {
            return
        }

        doChange := GuiWrapper.Confirm("Are you sure you want to delete this WinSet?", APP_NAME)

        if (!doChange) {
            return
        }

        this._currEntry.mods.winSets.removeAt(this._currWinSet)

        this._refreshWinSetsUI()
        this._isClean := false
        this._host.refreshUIStatus()
    }

    selWinSet(idx) {
        isDblClick := A_GuiEvent == "DoubleClick"
        this._currWinSet := idx

        if (!isDblClick) {
            return
        }

        this._addUpdateWinSet(true)
    }

    _addUpdateWinSet(prevEntry := false) {
        titlePrefix := prevEntry ? "Edit" : "Add"
        prevVal := prevEntry && this._currWinSet ? this._currEntry.mods.winSets[this._currWinSet] : ""
        InputBox, newEntry, % titlePrefix . " WinSet", % "Please enter an WinSet Configuration.`n`nExample: ""AlwaysOnTop, On"", to set a window to be Always On Top`n`nSee README for more info.",,,220,,,,, % prevVal

        if (!newEntry) {
            return
        }

        if (prevEntry && this._currWinSet) {
          this._currEntry.mods.winSets.removeAt(this._currWinSet)
          this._currEntry.mods.winSets.insertAt(this._currWinSet, newEntry)
        } else {
          this._currEntry.mods.winSets.push(newEntry)
        }

        this._refreshWinSetsUI()
        this._isClean := false
        this._host.refreshUIStatus()
    }
}