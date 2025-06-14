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
    rm -rf ~/.config/wezterm
    mklink /j ("~/.config/wezterm" | path expand)  ('~/src/wezterm-config/wezterm' | path expand --strict)

    nu ./windows-terminal/install.nu

[private]
clean:
    rm -rf ~/.config/wezterm
    rm -rf ~/.config/zellij

