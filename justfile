set shell := ["nu", "--config", "~/src/nushell-config/config.nu", "-c"]

[linux]
install:
    ln -sf ~/src/wezterm-config ~/.config/wezterm

[macos]
install:
    ln -shf ~/src/wezterm-config ~/.config/wezterm

[windows]
install:
    nu ./windows-terminal/install.nu
