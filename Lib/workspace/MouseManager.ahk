#Include <JSON>

class MouseManager {
    static CursorTypes := { "NWSE_SMALL": 32642
        , "NESW_SMALL": 32643
        , "WE_SMALL": 32644
        , "NS_SMALL": 32645
        , "NSEW_SMALL": 32646
        , "IDC_NO": 32648
        , "IDC_HAND": 32649
        , "IDC_APPSTARTING": 32650
        , "IDC_HELP": 32651
        , "NS_BIG": 32652
        , "WE_BIG": 32653
        , "NSEW_BIG": 32654
        , "N_BIG": 32655
        , "S_BIG": 32656
        , "W_BIG": 32657
        , "E_BIG": 32658
        , "NW_BIG": 32659
        , "NE_BIG": 32660
        , "SW_BIG": 32661
        , "SE_BIG": 32662 }

    MouseInfo[] {
        get {
            MouseGetPos, X, Y, winHWnd
            return { x: X, y: Y, hWnd: winHWnd }
        }
    }

    _cursHWnd := 0

    class SetCursor extends JSON.Functor {
        Call(self, cursorType) {
            cursHwnd := 0

            if cursorType is integer
            {
                cursHwnd := this._loadWinCursor(cursorType)
            }
            else if cursorType is Alpha
            {
                cursHwnd := this._loadFileCursor(cursorType)
            }

            this._setCursor(cursHwnd)
        }

        _loadWinCursor(cursorType) {
            return DllCall("LoadCursor"
                , "UInt"
                , NULL
                , "Int"
                , cursorType
                , "UInt")
        }

        _loadFileCursor(fileName) {
            return DllCall("LoadCursorFromFile", "Str", fileName)
        }

        _setCursor(cursHwnd) {
            AllCursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
            Loop, Parse, AllCursors, `,
            {
                DllCall("SetSystemCursor", "Uint", cursHwnd, "Int", A_Loopfield)
            }
        }
    }

    ResetCursor() {
        SPI_SETCURSORS := 0x57
        DllCall("SystemParametersInfo", "UInt", SPI_SETCURSORS, "UInt", 0, "UInt", 0, "UInt", 0)
    }
}