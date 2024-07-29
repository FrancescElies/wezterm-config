# An `ALT+key` centric wezterm config

Wezterm gives you cross platform tmux like capabilities (linux, mac and windows too).

This wezterm config is organized around the `ALT+key` where key is one of the following:

- `h j k l` for moving between splits (add `SHIFT` for resizing instead)
- wezterm `a`ction (command palette)
- `f`ind inside pane
- `c`opy mode
- show all k`e`y bindings
- `q`uit current pane
- `x` closes current nvim pane or terminal pane
- `s`wap pane
- `-`for vertical split and `\` for horizontal split pane
- `r`otate panes clockwise (add `SHIFT` for counter clockwise)
- insert `u`nicode character (e.g. insert an emoji)
- open lazy`g`it in split pane (add `SHIFT` for vertical split)
- open `b`root in split pane (add `SHIFT` for vertical split)

## Workspaces

Workspace related bindings are under `ALT+SHIFT`:

- `f`uzzy switch or create new `w`orkspace,
- `n`ext worskpace and `p`revious workspace
- new `s`ession: creates a workspace from existing project under `~/src`

There is more than just this, but the above is what you might need most of the time.
