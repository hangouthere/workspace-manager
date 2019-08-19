#Include <JSON>
#Include <workspace/MonitorManager>
#Include <workspace/WindowManager>

NAME_UNSAVED := "[Unsaved].json"

class WorkspaceManager
{
    fileName := ""
    config := 0
    entryListNames := ""

    Name[] {
        get {
            SplitPath, % this.fileName, OnlyFileName
            _name := StrReplace(OnlyFileName, ".json", "")
            _name := StrReplace(_name, "_", " ")
            return _name
        }
    }

    __New(FileName) {
        this.fileName := FileName
    }

    loadConfig(fileName := 0) {
        if (!fileName) {
            fileName := this.fileName
        }

        try {
            this.config := JSON.FromFile(fileName)
            this.fileName := fileName

            WorkspaceManager.NormalizeValues(this.config)
        } catch e {
            throw Exception("Unable to load Workspace Config: " . fileName . "`n" . e.Message, -1)
        }

        this.refresh()
    }

    saveConfig(OutFileName := 0) {
        saveConfig := Util.Array_DeepClone(this.config)

        For idx, entry in saveConfig.entries {
            ; Normalize just in case!
            WorkspaceManager.NormalizeEntry(entry)

            if (entry.monitor = 1) {
                entry.delete("monitor")
            }

            if (false = entry.forced) {
                entry.delete("forced")
            }

            if (true = Util.ArrayIsEmpty(entry.dimensions)) {
                entry.delete("dimensions")
            }

            if (true = Util.ArrayIsEmpty(entry.inputs.entries)) {
                entry.inputs.delete("entries")
            }

            if (true = Util.ArrayIsEmpty(entry.mods.winSets)) {
                entry.mods.delete("winSets")
            }
        }

        jsonDump := JSON.Dump(saveConfig,, 2)

        hasSuppliedName := OutFileName ? true : false
        OutFileName := hasSuppliedName ? OutFileName : this.fileName

        fileWriter := FileOpen(OutFileName, "w")

        if !IsObject(fileWriter) {
            throw Exception("Can't open file for writing: " . OutFileName)
        }

        fileWriter.Write(jsonDump)
        fileWriter.Close()

        if (true = hasSuppliedName) {
            this.fileName := OutFileName
        }
    }

    wipeConfig() {
        global NAME_UNSAVED

        newConfig := {}
        WorkspaceManager.NormalizeValues(newConfig)
        this.fileName := NAME_UNSAVED
        this.config := newConfig
        this.refresh()
    }

    runConfig() {
        numWindowsBuilt := 0
        numWindowsSkipped := 0
        skippedReasons := []
        settings := this.config.Settings

        windowMgr := new WindowManager()

        ; Set various alterations from Settings
        SetTitleMatchMode, % settings.WinSearchMode
        DetectHiddenWindows, % settings.SearchHiddenWindows ? "On" : "Off"

        ; Loop over every Config Entry
        For idx, entry in this.config.Entries {
            try {
                didRun := windowMgr.processEntry(entry, settings)

                if (true = didRun) {
                    numWindowsBuilt += 1
                } else {
                    numWindowsSkipped += 1
                }
            } catch err {
                numWindowsSkipped += 1
            }

            Sleep 200
        }

        if (true = settings.ShowFinish) {
            MsgBox,, Workspace Manager, % "Workspace Laid Out!`n`nBuilt:`t" . numWindowsBuilt . "`nSkipped:`t" . numWindowsSkipped, Timeout]
        }

        return { Built: numWindowsBuilt, Skipped: numWindowsSkipped }
    }

    addEntry(newEntry, newIdx := "") {
        WorkspaceManager.NormalizeEntry(newEntry)
        idx := 0

        if (newIdx) {
            this.config.Entries.insertAt(newIdx, newEntry)
            idx := newIdx
        } else {
            idx := this.config.Entries.push(newEntry)
        }

        this.refresh()

        return idx
    }

    removeEntryAt(index) {
        oldEntry := this.config.Entries.removeAt(index)

        this.refresh()

        return oldEntry
    }

    replaceEntryAt(index, newEntry) {
        WorkspaceManager.NormalizeEntry(newEntry)

        this.config.Entries.removeAt(index)
        this.config.Entries.insertAt(index, newEntry)

        this.refresh()
    }

    swapEntriesAt(idxA, idxB) {
        oldA := this.config.Entries[idxA]
        oldB := this.config.Entries[idxB]

        this.config.Entries[idxA] := oldB
        this.config.Entries[idxB] := oldA

        this.refresh()
    }

    refresh() {
        this.entryListNames := this._buildEntryList(this.config.Entries)
    }

    _buildEntryList(entryList) {
        outList := ""
        entries := entryList ? entryList : []

        For idx, entry in entries {
            outList .= entry.title . "|"
        }

        return "|" . SubStr(outList, 1, -1)
    }

    class BuildEntryDisplayName extends JSON.Functor {
        Call(self, entry) {
            if (entry.title) {
                return Trim(entry.title)
            }

            outName := ""

            if (entry.winTitle) {
                outName .= entry.winTitle
            }

            if (entry.winClass) {
                outName .= " " . entry.winClass
            }

            if (!outName) {
                if (entry.executable) {
                    outName := entry.executable
                } else {
                    outName := "NA"
                }
            }

            return Trim(outName)
        }
    }

    class NormalizeSettings extends JSON.Functor {
        Call(self, ByRef settings) {
            settings.TTY_FindWindow := settings.TTY_FindWindow ? settings.TTY_FindWindow : 10
            settings.ShowFinish := settings.ShowFinish ? settings.ShowFinish : false
            settings.SkipMissingMonitors := settings.SkipMissingMonitors ? settings.SkipMissingMonitors : false
            settings.WinSearchMode := settings.WinSearchMode ? settings.WinSearchMode : 2
            settings.SearchHiddenWindows := settings.SearchHiddenWindows ? settings.SearchHiddenWindows : false
        }
    }

    class NormalizeEntry extends JSON.Functor {
        Call(self, ByRef entry) {
            entry.title := WorkspaceManager.BuildEntryDisplayName(entry)
            entry.dimensions := entry.dimensions ? entry.dimensions : {}
            entry.mods := entry.mods ? entry.mods : {}
            entry.mods.minMax := entry.mods.minMax ? entry.mods.minMax : 0
            entry.mods.winSets := entry.mods.winSets ? entry.mods.winSets : []
            entry.inputs := entry.inputs ? entry.inputs : {}
            entry.inputs.mode := entry.inputs.mode ? entry.inputs.mode : 3
            entry.inputs.entries := entry.inputs.entries ? entry.inputs.entries : []

            entry.forced := entry.forced ? true : false
            entry.monitor := entry.monitor ? entry.monitor : 1

            ; Ensure junk is removed just in case
            entry.delete("executablePath")
            entry.delete("hWnd")
            entry.delete("monitorInfo")
            entry.delete("pid")
            entry.dimensions.delete("globalX")
            entry.dimensions.delete("globalY")

            return entry
        }
    }

    class NormalizeValues extends JSON.Functor {
        Call(self, ByRef config) {
            config.Entries := config.Entries ? config.Entries : []
            config.Settings := config.Settings ? config.Settings : {}

            WorkspaceManager.NormalizeSettings(config.Settings)

            For idx, entry in config.Entries {
                WorkspaceManager.NormalizeEntry(entry)
            }
        }
    }
}