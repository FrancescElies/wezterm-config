set shell := ["nu", "--config", "~/src/nushell-config/config.nu", "-c"]

install:
    symlink -f ~/src/wezterm-config ~/.config/wezterm
