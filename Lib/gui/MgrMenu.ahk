class MgrMenu {
    _host := 0
    _wsm := 0
    _gui := 0

    __New(gui, host, wsm) {
        this._gui := gui
        this._host := host
        this._wsm := wsm

        wsMenu := gui.StartMenu("Workspace")
        entriesMenu := gui.StartMenu("Entries")
        mainMenu := gui.StartMenu("MainMenu")
        helpMenu := gui.StartMenu("HelpMenu")

        wsMenu.AddMenuItem("&New", this.mnu_newWorkspace.bind(this))
        wsMenu.AddSeparator()
        wsMenu.AddMenuItem("&Run", this.mnu_runWorkspace.bind(this))
        wsMenu.AddSeparator()
        wsMenu.AddMenuItem("&Load...", this.mnu_openWorkspace.bind(this))
        wsMenu.AddMenuItem("&Save", this.mnu_saveWorkspace.bind(this))
        wsMenu.AddMenuItem("Save &As...", Util.DoubleBind(this.mnu_saveWorkspace.bind(this), true))
        helpMenu.AddMenuItem("&Wiki", this.mnu_openURL.bind(this, "https://bitbucket.org/nerdfoundrygaming/workspace-manager/wiki"))
        helpMenu.AddMenuItem("&Issues", this.mnu_openURL.bind(this, "https://bitbucket.org/nerdfoundrygaming/workspace-manager/issues?status=new&status=open"))
        helpMenu.AddMenuItem("&Discord", this.mnu_openURL.bind(this, "http://rebrand.ly/nfgToolsDiscord"))
        helpMenu.AddSeparator()
        helpMenu.AddMenuItem("&About", this.mnu_about.bind(this))

        entriesMenu.AddMenuItem("&Delete...", this.mnu_deleteEntry.bind(this))
        entriesMenu.AddMenuItem("&Save...", this.mnu_saveEntry.bind(this))
        entriesMenu.AddSeparator()
        entriesMenu.AddMenuItem("Add &Blank", this.mnu_addBlankEntry.bind(this))
        entriesMenu.AddMenuItem("&Hunt for a Window...", this.mnu_huntWindow.bind(this))

        mainMenu.AddSubMenu("&Workspace", wsMenu)
        mainMenu.AddSubMenu("&Entries", entriesMenu)
        mainMenu.AddSubMenu("&Help", helpMenu)

        gui.SetWindowMenu(mainMenu)
    }

    ;;; Menu Handlers ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mnu_openURL(url) {
        Run, % url
    }

    mnu_about() {
        global APP_NAME
        global APP_VERSION

        MsgBox,,% "About " . APP_NAME, % "Created with <3 by nfgCodex`n`n" . APP_VERSION
    }

    mnu_newWorkspace() {
        global NAME_UNSAVED

        if (true = this._host.isDirty) {
            wipeConfig := GuiWrapper.Confirm("Your workspace is unsaved, continuing will lose all unsaved changes.`nAre you sure you want to create a new workspace?")

            if (false = wipeConfig) {
                return
            }
        }

        this._host._tabEntries.reset()
        this._wsm.wipeConfig()
        this._host.refreshUI()
        this._host._tabEntries.addDirtyEntry({ title: "New Entry" })
    }

    mnu_runWorkspace() {
        if (this._host.isDirty) {
            return
        }

        this._wsm.runConfig()
    }

    mnu_openWorkspace() {
        if (this._host.isDirty) {
            return
        }

        FileSelectFile, ChosenFile, , , Select Workspace Configuration, WS JSON Config Files (*.json)

        if (!ChosenFile) {
            return
        }

        this._host.loadConfig(ChosenFile)
        this._host.refreshUI(1)

        this._host.wsm.fileName
    }

    mnu_saveWorkspace(saveAs := false) {
        if (this._host._tabEntries.isDirty) {
            return
        }
        this._host.saveWorkspace(saveAs)
    }

    mnu_deleteEntry() {
        this._host._tabEntries.deleteEntry()
    }

    mnu_saveEntry() {
        this._host._tabEntries.saveEntry()
    }

    mnu_addBlankEntry() {
        if (this._host.isDirty) {
            return
        }
        this._host._tabEntries.addDirtyEntry({ title: "New Entry" })
    }

    mnu_huntWindow() {
        if (this._host.isDirty) {
            return
        }
        this._host._tabEntries.windowHunt()
    }
}