# Window Manager

### by nfgCodex

> This Project is based on [AutoHotKey](https://www.autohotkey.com), which is a very powerful scripting tool! Check it out!

In a means to define a configuration to build workspaces, which seems to be a very common goal, albeit minimal at times (due to complexity) with AHK.

I've come up with this format, that hopefully will help others build workspaces of their own with ease!

This is useful to maximize productivity as you start a particular type of workload.

For example, you may want to create a workspace for the following types of workloads:

- Photo/Video editing
- Data-entry work routine
- Streaming to Mixer/Twitch

With some configuration, you can quickly have a workspace for any occasion!

![Demo](./WindowManager_Demo.gif)

## Install / Example

> Be sure to check out the [README_Example.md](./README_Example.md) file for the dirty deets.

Download the [Release](./ahk.WindowManager_Release.zip) or look in the [Downloads](https://bitbucket.org/nerdfoundrygaming/ahk.windowmanager/downloads/) for archives including the [Default Config](./WindowConfig.json).

## Setup

1. Configure `WindowConfig.json`
2. Run `WindowManager.exe` (or `index.ahk` if running from source)
3. (Optional) Install [AutoHotKey](https://www.autohotkey.com) (henceforth AHK)
   - Useful for **Window Spy**
   - Necessary if you want to run from source

### Configuring `WindowConfig.json`

Top-Level FULL structure is as follows:

```
{
    "Settings": { ... },
    "Entries": [{ ... }, { ... }, ...],
}
```

| Value    | Type                             | Meaning                                                               |
| -------- | -------------------------------- | --------------------------------------------------------------------- |
| Settings | Settings Struct, Optional        | Global Settings for Entries and run-time.                             |
| Entries  | Collection of `Entry` structures | Collection of `Entry` structures for the **Window Manager** to build. |

#### Settings Struct

`Settings` are considered global settings that apply to every Entry in the list, and it can contain the following values:

```
{
    "TTY_FindWindow": 45,
    "ShowFinish": true,
    "SkipMissingMonitors": true
}
```

| Setting | Type | Meaning |
| ------- | ---- |collection of `Entry` structures------- | ------------------------------------------------------ |
| TTY_FindWindow | Integer, Default = 10 | How long to wait to find window on `Entry.identifier`. If this TTY yields, then the Entry will be abandoned. |
| ShowFinish | Boolean, Default = false | Whether or not to show a final message on completion. |
| SkipMissingMonitors | Boolean, Default = false | If enabled, Windows targeted for missing monitors will be skipped. Otherwise, calculations default to the Primary Monitor for offset/percentage calculations. |

#### Entries Collection

`Entires` are a collection of `Entry` structures for the WindowManager to operate with:

```
[
    { Entry1 },
    { EntryN },
    ...
]
```

##### Entry

An `Entry` defines how to find, create (if not found), and size/style the window:

```
{
   "identifier": "ahk_class Notepad",
   "executable": "c:\\windows\\notepad.exe",
   "dimensions": {
     "monitor": 1,
     "width": "50%",
     "height": "50%",
     "x": 0,
     "y": "0"
   },
   "mods": {
     "WinSet": [
       ["Style", "-0x10000"],
       ["Style", "-0x20000"],
       ["Style", "-0x40000"]
     ]
   }
}
```

There's lots of optional data, as well as different types of values you can place in certain fields:

| Setting                                                                                                                                                                                                                       | Type                                                                                     | Meaning                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| identifier                                                                                                                                                                                                                    | [AHK WinTitle](https://www.autohotkey.com/docs/misc/WinTitle.htm)                        | Identifies a window with varying specificity to manipulate. If a window cannot be identified one will be created, and then awaited until creation is complete and matches this `identifier`. A maximum seconds defined by `Settings.TTY_FindWindow` will wait until the Entry is abandoned (left in place). Title must fully comply with [AHK WinTitle](https://www.autohotkey.com/docs/misc/WinTitle.htm). If the value starts with `force` or `F⎮` (that's "Capital F, Pipe") then it will force a new instance to start and then search for the remainder of the identifier value. If _not_ `force`d, and no `identifier` is set, then the Entry will be skipped. An `Entry` that _is_ `force`d but without an `identifier`, the `executable` will be ran but reliability on waiting/resizing is volatile and may bottleneck startup. **Pro-tip**: Use "Window Spy" that comes with AHK to help target a window more specifically with _Title_ and `ahk_class` matches. |
| executable                                                                                                                                                                                                                    | [AHK Run](https://www.autohotkey.com/docs/commands/Run.htm) Target                       | Anything `AHK Run.Target` can run. See [AHK Run](https://www.autohotkey.com/docs/commands/Run.htm) Target (and Remarks) to get an idea of full capabilities. Some useful Ideas: URLs, Path's to Shortcut.lnk's, Direct Path's to EXE files                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| dimensions                                                                                                                                                                                                                    | Dimensions Struct, Optional                                                              | If set, will move your desired window to location.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| dimensions.monitor                                                                                                                                                                                                            | Number, Default = 1                                                                      | If set, all calculations are offset by the Monitor's offset. See more below.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| dimensions.x, dimensions.y, dimensions.width, dimensions.height                                                                                                                                                               | Number or String (Percent), Default = 0                                                  | Defines the position on the specified Monitor. Depending on the type of value sent, calculations will be made differently: **Integers**: (_Positive_: Offset calculated from Top-Left.) (_Negative_: Offset calculated from Bottom-Right.), **Percentage**: A calculation based on the Monitor Dimensions (sans toolbar space) will take place. Must be a positive value.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| mods                                                                                                                                                                                                                          | Mods Struct, Optional                                                                    | If set, apply modifications to the Window after identified                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| mods.[restore](https://www.autohotkey.com/docs/commands/WinRestore.htm), mods.[maximize](https://www.autohotkey.com/docs/commands/WinMaximize.htm), mods.[minimize](https://www.autohotkey.com/docs/commands/WinMinimize.htm) | Boolean, Default = `false`                                                               | If set to `true`, will perform expected action                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| mods.WinSet                                                                                                                                                                                                                   | Collection of [WinSet instructions](https://www.autohotkey.com/docs/commands/WinSet.htm) | If set, iterate over settings and apply to window targeted by `identifier`. See [AHK WinSet](https://www.autohotkey.com/docs/commands/WinSet.htm) subcommand page, supports up to 3 parameters (including subcommand). See model definition above for example.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |

## Multiple Configurations

> Right out of the box, **Window Manager** is set to read from `WindowConfig.json` sitting right next to the EXE/`index.ahk` file.

Multiple Configurations is easy to manage, just simply put a new config into a new file and give it a name after your workspace, like `photoEditing.json`.

Then launch the **Window Manager** with the path to the Configuration file after the command:

```
"C:\Program Files\AutoHotkey\AutoHotkey.exe" C:\WindowManager\index.ahk photoEditing.json
```

or (if using Released version)

```
C:\WindowManager\WindowManager.exe photoEditing.json
```

## Troubleshooting

#### My Extra Window Isn't Appearing

This typically happens because of a few reasons:

- Your `identifier` value is completely empty.
- Your `executable` target is invalid.
- Your `identifier` isn't specific enough and is selecting an existing process.
  - `ahk_exe explorer.exe` will target your taskbar if no other windows are open, so try `ahk_class CabinetWClass`.
  - Use **Window Spy** for help making your target more specific.
  - To make another window of similar type spawn, be sure to `force` the `Entry`.

#### My Window Isn't Resizing/Moving

- Your `identifier` value is completely empty.
- Your `identifier` isn't specific enough and is selecting an existing process.
  - A mis-entered `identifier` may result in never finding a matching window.
  - Finding the Window may have timed out
    - This may be due to the application taking a long time to process, consider lengthening `Settings.TTY_FindWindow`.
  - See _My Extra Window Isn't Appearing_ above.
