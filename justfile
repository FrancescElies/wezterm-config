set shell := ["nu", "--config", "~/src/nushell-config/config.nu", "-c"]

[unix]
install:
    ln -sf ~/src/wezterm-config ~/.config/wezterm

[windows]
install:
    nu ./windows-terminal/install.nu
