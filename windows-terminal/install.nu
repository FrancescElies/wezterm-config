# NOTE: everything needs to be backslashes

let wezterm_settings = ( '~\.config\wezterm'  | path expand --no-symlink )
let my_wezterm_config = ( '~\src\wezterm-config' | path expand --strict )  # must exist

print $"(ansi purple_bold)trying ($wezterm_settings) <=> ($my_wezterm_config)(ansi reset)"
try { rm --trash $wezterm_settings }
try { mklink /j $wezterm_settings  $my_wezterm_config }

# https:\\learn.microsoft.com\en-us\windows\terminal\install#settings-json-file
let settings = [
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'), # Terminal (stable \ general release)
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'), # Terminal (preview release)
    ($env.LOCALAPPDATA | path join 'Microsoft\Windows Terminal\settings.json') # Terminal (unpackaged: Scoop, Chocolatey, etc)
]
for settings_json in $settings {
    let src = ($my_wezterm_config | path join 'windows-terminal\settings.json')
    print $"(ansi purple_bold)trying ($settings_json) <=> ($src)(ansi reset)"
    try { rm --trash $settings_json }
    try { mklink $settings_json  $src }
}
