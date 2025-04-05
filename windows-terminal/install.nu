# NOTE: everything needs to be backslashes

# https:\\learn.microsoft.com\en-us\windows\terminal\install#settings-json-file
# settings live in different places depending on how it was installed :/
let setting_locations = [
    # Terminal (stable \ general release)
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    # Terminal (preview release)
    ($env.LOCALAPPDATA | path join 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    # Terminal (unpackaged: Scoop, Chocolatey, etc)
    ($env.LOCALAPPDATA | path join 'Microsoft\Windows Terminal\settings.json')
]
for link_name in $setting_locations {
    let target = ($my_wezterm_config | path join 'windows-terminal\settings.json')
    print $"(ansi pb)trying ($link_name) --> ($target)(ansi reset)"
    rm -f --trash $link_name
    mklink $link_name  $target
}
