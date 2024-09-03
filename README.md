# An `ALT+key` centric wezterm config

Wezterm gives you a cross-platform terminal and multiplexer with tmux like
capabilities that works on linux, mac and windows.

This wezterm config is organized around the `ALT+key` where key is one of the following:

General actions:

- wezterm `a`ction (command palette)
- show `d`ebug layer
- insert `u`nicode character (e.g. insert an emoji)

Managing panes:

- `v`ertical split or alternavtively `-`
- `h`orizontal split or `\`
- `h j k l` for moving between splits (add `SHIFT` for resizing instead)
- `x` closes current pane, use `q`uit to close without asking
- `n`ext and `p`revious pane
- s`w`ap pane
- `r`otate panes clockwise (add `CTRL` for counter clockwise)
- `z`oom in/out pane

Inside a pane:

- `f`ind text
- `c`opy mode

Quickly open commonly used programs in split pane with `ALT+key` or
`CTRL+ALT+key` for a vertical split pane:

- open nvim and `e`dit visible area and entire scrollback of the active pane
- open lazy`g`it in split pane
- open `b`root in split pane
- open `t`odos in split pane
- open `m`onitoring (bottom) in split pane

## Workspaces

Workspace related bindings are under `ALT+SHIFT+key`:

- `A`dd a new workspace,
- go to `D`efault workspace,
- go to open `W`orkspace
- new `S`ession: creates a workspace from existing project under `~/src`
- `N`ext and `P`revious workspace

## Window

Window related bindings are under `ALT+SHIFT+key`:

- Always on `T`op
- Always on `B`ottom

There is more than just this, but the above is what you might need most of the time.
