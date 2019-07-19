# Window Manager: Example
### by nfgCodex

This supplied config does a couple things to showcase the different ways of entering dimensions, as well as forcing repeated windows to open.

If you browse the [Example Config File](./WindowConfig.json), you'll notice the following Eight (8) Windows being set up, with the special notes pointed out:

* Notepad 1
    * `dimensions` setting the `width` and `height` with percentages to calculate on-the-fly.
    * Setting `mods.WinSet` to take away the max/min buttons, and disable resizing.
* Explorer (to C:\)
    * `dimensions` setting the `y` with percentages to calculate on-the-fly.
* A URL: http://google.com
    * `dimensions` setting the `height` to `100%` will ensure to set the browser full height.
    * Setting `mods.restore` to make sure the `identifier` window is not maximized nor minimized.
* A URL: https://bitbucket.org/nerdfoundrygaming/ahk.windowmanager
    * No `dimensions` set, as we're expecting a new tab on the previous window
* Notepad 2
    * `force` defined, with additional `indentifier` for stability.
* Notepad 3
    * `force` defined with shorthand `F|`, with additional `indentifier` for stability.
* Notepad 4
    * `force` defined but no `indentifier`. Must rely on `PID` from creating window via return from `executable` Target.
* Notepad 5
    * Setting `mods.WinSet` to take away the window control box 
    * **Must close via menu!**
* Notepad 7-12
    * These all spawn on Monitor 2!
    * If you don't have 2 monitors, the Default Config is configured to skip them.

### Did You Notice?

One Entry is ALWAYS skipped, regardless of Monitor count. Why was an Entry skipped? 

Because an `identifier` wasn't supplied, and we didn't explicitly set it to `force` or `F|`!