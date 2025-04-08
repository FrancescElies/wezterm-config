# NOTE: everything needs to be backslashes

let this_repo = ( '~\src\wezterm-config' | path expand --strict )  # must exist

# https:\\learn.microsoft.com\en-us\windows\terminal\install#settings-json-file
let settings = [
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'), # Terminal (stable \ general release)
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'), # Terminal (preview release)
    ($env.LOCALAPPDATA | path join 'Microsoft\Windows Terminal\settings.json') # Terminal (unpackaged: Scoop, Chocolatey, etc)
]
for link_name in $settings {
    let target = ($this_repo | path join 'windows-terminal\settings.json')
    print $"(ansi purple_bold)trying ($link_name) <=> ($target)(ansi reset)"
    try { rm --trash $link_name }
    try { mklink $link_name  $target }
}
