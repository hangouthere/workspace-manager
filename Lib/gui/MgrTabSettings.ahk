class MgrTabSettings {
    AttachToGui(gui, host) {
        prxyUpd := host.updateSettings.Bind(host) 

        gui.EditTab(2)

        gui.EditFont("s20")
        gui.addControl("_", "Text", "x16 y32 +0x200", "WorkSpace Settings")
        gui.EditFont()
        gui.addControl("Settings.SkipMissingMonitors", "CheckBox", "x24 y80", "Skip Missing Monitors", Util.DoubleBind(prxyUpd, "Settings.SkipMissingMonitors"))
        gui.addControl("Settings.ShowFinish", "CheckBox", "x24 y112 ", "Show Completion Stats", Util.DoubleBind(prxyUpd, "Settings.ShowFinish"))
        gui.addControl("_", "Text", "x24 y142 +0x200", "Window Search TTY")
        gui.addControl("_", "Edit", "x140 y139 w50 Number")
        gui.addControl("Settings.TTY_FindWindow", "UpDown", "x167 y139",, Util.DoubleBind(prxyUpd, "Settings.TTY_FindWindow"))
        gui.addControl("_", "Text", "x24 y173 +0x200", "Window Search Mode")
        gui.addControl("Settings.WinSearchMode", "DropDownList", "x140 y170 AltSubmit", "Starts With Text||Title Contains Text|Exact Match Text", Util.DoubleBind(prxyUpd, "Settings.WinSearchMode"))
        gui.addControl("Settings.SearchHiddenWindows", "CheckBox", "x24 y202", "Search for Hidden Windows", Util.DoubleBind(prxyUpd, "Settings.SearchHiddenWindows"))
    } 
}