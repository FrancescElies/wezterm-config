set shell := ["nu", "--config", "~/src/nushell-config/config.nu", "-c"]

# `ln -n` treat LINK_NAME as a normal file if it is a symbolic link to a directory
[linux]
install:
    ln -snf ~/src/wezterm-config ~/.config/wezterm

# `ln -h` do not follow symlink. This is most useful with the -f option,
#         to replace a symlink which may point to a directory.
[macos]
install:
    ln -shf ~/src/wezterm-config ~/.config/wezterm

[windows]
install:
    nu ./windows-terminal/install.nu
