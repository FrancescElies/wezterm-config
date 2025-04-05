set shell := ["nu", "-c"]

# `ln -n` treat LINK_NAME as a normal file if it is a symbolic link to a directory
[linux]
install: clean
    ln -snf ("./wezterm" | path expand) ~/.config/wezterm
    ln -snf ("./zellij" | path expand) ~/.config/zellij

# `ln -h` do not follow symlink. This is most useful with the -f option,
#         to replace a symlink which may point to a directory.
[macos]
install: clean
    ln -shf ("./wezterm" | path expand) ~/.config/wezterm
    ln -shf ("./zellij" | path expand) ~/.config/zellij

[windows]
install:
    let link_name = ('.'  | path expand --no-symlink)
    rm -f --trash $link_name
    mklink /j $link_name  ('~/src/wezterm-config/wezterm' | path expand --strict)

    nu ./windows-terminal/install.nu

[private]
clean:
    rm -f --trash ~/.config/wezterm
    rm -f --trash ~/.config/zellij

