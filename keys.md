Some useful key bindings, see defaults [here](https://github.com/wez/wezterm/blob/main/docs/config/default-keys.md)

| Modifiers | Key | Action |
| --------- | --- | ------ |
| `CTRL+SHIFT`     | `c`   | `CopyTo="Clipboard"`  |
| `CTRL+SHIFT`     | `v`   | `PasteFrom="Clipboard"`  |
| --------- | --- | ------ |
| `CTRL`    | `Insert` | `CopyTo="PrimarySelection"` {{since('20210203-095643-70a364eb', inline=True)}} |
| `SHIFT`     | `Insert` | `PasteFrom="PrimarySelection"` |
| --------- | --- | ------ |
| `CTRL`    | `Tab` | `ActivateTabRelative=1` |
| `CTRL`      | `-`      | `DecreaseFontSize` |
| `CTRL`      | `=`      | `IncreaseFontSize` |
| `CTRL`      | `0`      | `ResetFontSize` |
| --------- | --- | ------ |
| `CTRL+SHIFT`     | `n`      | `SpawnWindow` |
| `CTRL+SHIFT`     | `t`      | `SpawnTab="CurrentPaneDomain"` |
| `CTRL+SHIFT`     | `w`      | `CloseCurrentTab{confirm=true}` |
| `CTRL+SHIFT`     | `1`      | `ActivateTab=0` |
| `CTRL+SHIFT`     | `2`      | `ActivateTab=1` |
| `CTRL+SHIFT`     | `Tab` | `ActivateTabRelative=-1` |
| `CTRL+SHIFT`     | `R`    | `ReloadConfiguration` |
| `CTRL+SHIFT`     | `K`    | `ClearScrollback="ScrollbackOnly"` |
| `CTRL+SHIFT`     | `L`    | `ShowDebugOverlay` |
| `CTRL+SHIFT`     | `P`    | `ActivateCommandPalette` |
| `CTRL+SHIFT`     | `U`    | `CharSelect` |
| `CTRL+SHIFT`     | `F`    | `Search={CaseSensitiveString=""}` |
| `CTRL+SHIFT`     | `X`    | `ActivateCopyMode` |
| `CTRL+SHIFT`     | `Space`| `QuickSelect` {{since('20210502-130208-bff6815d', inline=True)}} |
| --------- | --- | ------ |
| `ALT` | `-`    | `SplitVertical={domain="CurrentPaneDomain"}` |
| `ALT` | `\`    | `SplitHorizontal={domain="CurrentPaneDomain"}` |
| `ALT`        | `x`      | `CloseCurrentPane` |
| --------- | --- | ------ |
| `CTRL+SHIFT+ALT` | `LeftArrow`    | `AdjustPaneSize={"Left", 1}` |
| `CTRL+SHIFT+ALT` | `RightArrow`   | `AdjustPaneSize={"Right", 1}` |
| `CTRL+SHIFT+ALT` | `UpArrow`      | `AdjustPaneSize={"Up", 1}` |
| `CTRL+SHIFT+ALT` | `DownArrow`    | `AdjustPaneSize={"Down", 1}` |
| `CTRL+SHIFT`     | `LeftArrow`    | `ActivatePaneDirection="Left"` |
| `CTRL+SHIFT`     | `RightArrow`    | `ActivatePaneDirection="Right"` |
| `CTRL+SHIFT`     | `UpArrow`    | `ActivatePaneDirection="Up"` |
| `CTRL+SHIFT`     | `DownArrow`    | `ActivatePaneDirection="Down"` |
| `CTRL+SHIFT`     | `Z`    | `TogglePaneZoomState` |

