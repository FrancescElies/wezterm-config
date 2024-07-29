set shell := ["nu", "--config", "~/src/nushell-config/config.nu", "-c"]

[unix]
install:
    ln -sf ~/src/wezterm-config ~/.config/wezterm

[windows]
install:
    mklink /D ( ~/.config/wezterm  | path expand --no-symlink | path split | path join ) ( ~/src/wezterm-config | path expand --strict | path split | path join)
