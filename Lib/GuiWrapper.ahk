; Based on evilC's work, but heavily modified by nfgCodex
; Original Source: https://www.autohotkey.com/boards/viewtopic.php?p=117072&sid=d68446c392c73e3aa4f496902d7306d0#p117072
; Major changes:
;   * Values are held in memory instead of INI file
;   * Tabs Support
;   * Font Support
;   * Menu Support

class GuiWrapper {
	static _SkipChangeDetection := {groupbox: 1}
	static _CheckTypes := {checkbox: 1, radio: 1}
	static _ListTypes := {ddl: 1, dropdownlist: 1, combobox: 1, listbox: 1}

	Ctrls := {}
	RadioGroups := {}
	Menus := {}
    Values := {}
	hwnd := 0
	_CurrentRadioGroup := 0
	_RadioGroupCount := 0

	ident[] {
		get {
			return "ahk_id " . this.hwnd
		}
	}

	__New(name := 0, initOptions := 0){
		if (name){
			Gui, % name . ":New", % "+Hwndhwnd " . initOptions
		} else {
			Gui, % "+Hwndhwnd " . initOptions
		}

		this.name := name
		this.hwnd := hwnd
	}

    ; 1 = type, 2 = options, 3 = init value
	addControl(name, aParams*){
		is_radio := (aParams[1] = "radio")
		is_radio_in_group := (is_radio && this._RadioGroupCount)
		is_checktype := ObjHasKey(this._CheckTypes, aParams[1])
		is_listtype := ObjHasKey(this._ListTypes, aParams[1])

        if (is_checktype){
			; Is of a type the uses "Checked" in the options to signify default value
			; strip checked from options, use it as default value
			aParams[2] := RegExReplace(aParams[2], "\bchecked\b", "", checked)
			; If not a radio that is in a group, get it's value from the INI file
			if (!is_radio_in_group){
				checked := this._ReadSetting(name)
				aParams[2] .= (checked ? " checked" : "")
			}
		}

		; If we are mid-radio group, and this is not the first radio, then remove WS_GROUP
		if (this._RadioGroupCount > 1){
			aParams[2] .= " -0x20000"
		}

		; Create the GuiControl
		ctrl := new this.GuiControl(this, name, aParams*)
		this.Ctrls[name] := ctrl

		; If this is a radio and we are mid radio group, then add it to the list and progress _RadioGroupCount
		if (is_radio_in_group){
			this.RadioGroups[this._CurrentRadioGroup]._AddRadio(ctrl)
			ctrl._RadioGroupName := this._CurrentRadioGroup
			this._RadioGroupCount++
		}

		return ctrl
	}

	StartMenu(name) {
			this.Menus[name] := new this.Menu(name)
			return this.Menus[name]
	}

	SetWindowMenu(newMenu) {
			Gui, % this.hwnd ":Menu", % newMenu.Name
	}

	StartRadioGroup(name, default := 1, callback := 0){
		this.RadioGroups[name] := new this.RadioGroup(this, name, default, callback)
		this._CurrentRadioGroup := name
		this._RadioGroupCount := 1
		return this.RadioGroups[name]
	}

	EndRadioGroup() {
		cg := this.RadioGroups[this._CurrentRadioGroup]
		; Load settings from the ini file, fire initial callback for group
		cg.Set(this._ReadSetting(this._CurrentRadioGroup), 0)
		this._CurrentRadioGroup := 0
		this._RadioGroupCount := 0
	}

	EditTab(tabId := 0) {
			if (tabId) {
					Gui, % this.hwnd ":Tab", % tabId
			} else {
					Gui, % this.hwnd ":Tab"
			}
	}

	EditFont(FontInfo := 0) {
			if (FontInfo) {
					Gui, % this.hwnd ":Font", % FontInfo
			} else {
					Gui, % this.hwnd ":Font"
			}
	}

	Show(aParams*){
		Gui, % this.hwnd ":Show", % aParams[1], % aParams[2]
	}

	Close(){
		WinClose, % this.ident
	}

	Focus() {
		WinActivate, % this.ident
	}

	_ControlChanged(ctrl){
		this._WriteSetting(ctrl.name, ctrl.Get())
	}

	_RadioGroupChanged(name, index){
		this.RadioGroups[name].Set(index)
		this._WriteSetting(name, index)
	}

	_ReadSetting(name){
		return this.Values[name]
	}

	_WriteSetting(name, value){
        this.Values[name] := value
	}

	class GuiControl {
		_ChangeValueCallback := 0
		_RadioGroupName := 0
		_RadioGroupIndex := 0

		;  aParams      1             2       3
		; Gui, Add, ControlType [, Options, Text]
        ;  aParams 4 = callback
		__New(ParentGui, Name, aParams*){
			this.ParentGui := ParentGui

			Gui, % ParentGui.hwnd ":Add", % aParams[1], % "hwndhwnd " aParams[2], % aParams[3]
			this.hwnd := hwnd
			this.Name := name
			this.Type := aParams[1]
			this.IsListType := ObjHasKey(this.ParentGui._ListTypes, this.Type)
			this.IsAltSumbit := RegExMatch(aParams[2], "\bAltSubmit\b")
			this.CanHaveHandler := !ObjHasKey(this.ParentGui._SkipChangeDetection, this.Type)

			if (IsObject(aParams[4])){
				this._ChangeValueCallback := aParams[4]
			}

			if (this.CanHaveHandler && this._ChangeValueCallback) {

				fn := this._ChangedValue.Bind(this)

				this.updateControl("+g", fn)
			}
		}

		addGraphicToControl(fileName, bWidth := 16, bHeight := 16, ImgType := 1) {
			LR_LOADFROMFILE := 16
			BM_SETIMAGE := 247
			image := DllCall("LoadImage", "UInt",, "Str", fileName, "UInt", ImgType, "Int", bWidth, "Int", bHeight, "UInt", LR_LOADFROMFILE, "UInt")
			DllCall("SendMessage", "UInt", this.hwnd, "UInt", BM_SETIMAGE, "UInt", ImgType,  "UInt", image)
		}

		updateControl(ctrlStatements*) {
			opt := ctrlStatements[1]
			val := ctrlStatements[2]

			GuiControl, % opt, % this.hwnd , % val
		}

		; The user interacted with the guicontrol
		_ChangedValue(aParams*){
			if (this._RadioGroupName){
				this.ParentGui._RadioGroupChanged(this._RadioGroupName, this._RadioGroupIndex)
			} else {
				this.Set(this.Get(), 0)	; Don't update the GuiControl
			}
		}

		Get(){
			GuiControlGet, value, , % this.hwnd
			return value
		}

		Set(value, update_guicontrol := 1, update_parent := 1, fire_callback := 1){
			if (update_guicontrol){
                isInt := false

                if value is integer
                    isInt := true

				if (this.IsListType and isInt){
					opt := "Choose"
				}

				this.updateControl(opt, value)
			}

			if (update_parent){
				this.ParentGui._ControlChanged(this)
			}

			if (fire_callback){
				if (this._ChangeValueCallback != 0){
					this._ChangeValueCallback.Call(value)
				}
			}
		}
	}

	class RadioGroup {
		Name := ""
		ParentGui := 0
		Radios := []
		ChangeValueCallback := 0

		__New(ParentGui, Name, default := 1, callback := 0){
			this.ChangeValueCallback := callback
			this.ParentGui := ParentGui
			this.Name := name
			this.Default := default
		}

		_AddRadio(ctrl){
			this.Radios.push(ctrl)
			ctrl._RadioGroupIndex := this.Radios.length()
		}

		Set(index){
			for i, radio in this.Radios {
				if (i == index)
					continue
				radio.Set(0, 1, 0)	; Don't update the parent
			}
			this.Radios[index].Set(1, 1, 0)
			if (this.ChangeValueCallback != 0){
				this.ChangeValueCallback.Call(index)
			}
		}
	}

	class Menu {
		Name := ""
		Items := {}

		__New(Name) {
			this.Name := Name
		}

        menuId[] {
            get {
                return % ":" . this.Name
            }
        }

		AddSeparator() {
			Menu, % this.Name, Add
		}

		AddMenuItem(itemName, callback) {
			if (callback) {
				Menu, % this.Name, Add, % itemName, % callback
			} else {
				Menu, % this.Name, Add, % itemName
			}
            this.Items[itemName] = itemName
		}

        AddSubMenu(submenuLabel, subMenu) {
            Menu, % this.Name, Add, % submenuLabel, % subMenu.menuId
            this.Items[subMenu.menuId] = submenuLabel
        }

		Toggle(submenuLabel, enabled := false) {
			Menu, % this.Name, % enabled ? "Enable" : "Disable", % submenuLabel
		}
	}

	class Prompt extends JSON.Functor {
		Call(self, msg, title := 0) {
			MsgBox, % 0x1 | 0x40, % title, % msg

			IfMsgBox, Ok
				return true

			return false
		}
	}

	class Confirm extends JSON.Functor {
		Call(self, msg, title) {
			MsgBox, % 0x4 | 0x20, % title, % msg

			IfMsgBox, Yes
				return true

			return false
		}
	}
}