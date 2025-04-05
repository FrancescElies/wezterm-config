set shell := ["nu", "-c"]

# `ln -n` treat LINK_NAME as a normal file if it is a symbolic link to a directory
[linux]
install:
    ln -snf ~/src/wezterm-config/wezterm ~/.config/wezterm
    ln -snf ~/src/wezterm-config/zellij ~/.config/zellij

# `ln -h` do not follow symlink. This is most useful with the -f option,
#         to replace a symlink which may point to a directory.
[macos]
install:
    ln -shf ~/src/wezterm-config/wezterm ~/.config/wezterm
    ln -shf ~/src/wezterm-config/zellij ~/.config/zellij

[windows]
install:
    let link_name = ('~/.config/wezterm'  | path expand --no-symlink)
    rm -f --trash $link_name
    mklink /j $link_name  ( ~/src/wezterm-config/wezterm | path expand --strict )

    nu ./windows-terminal/install.nu
