# An `ALT+key` centric wezterm config

Wezterm gives you cross platform tmux like capabilities (linux, mac and windows too).

This wezterm config is organized around the `ALT+key` where key is one of the following:

- `h j k l` for moving between splits (add `SHIFT` for resizing instead)
- `n`ext and `p`revious pane
- wezterm `a`ction (command palette)
- `f`ind inside pane
- show `d`ebug layer
- `c`opy mode
- `e`dit in nvim visible area and entire scrollback of the active pane
- `q`uit current pane
- `x` closes current nvim pane or terminal pane
- `s`wap pane
- `-`for vertical split and `\` for horizontal split pane
- `r`otate panes clockwise (add `CTRL` for counter clockwise)

Open commonly used programs quickly `ALT+key`:

- insert `u`nicode character (e.g. insert an emoji)
- open lazy`g`it in split pane (add `CTRL` for vertical split)
- open `b`root in split pane (add `CTRL` for vertical split)

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
