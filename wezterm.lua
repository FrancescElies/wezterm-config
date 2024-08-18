-- https://wezfurlong.org/wezterm/config/lua/keyassignment/
-- https://wezfurlong.org/wezterm/config/default-keys.html
-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm
-- https://github.com/wez/wezterm/discussions/2329

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local wezterm = require 'wezterm'
local workspace_sessionizer = require 'workspace_sessionizer'
local utils = require 'utils'
local platform = require 'platform'
local act = wezterm.action
local mux = wezterm.mux

local zettelkasten = wezterm.home_dir .. '/src/zettelkasten/'
-- Troubleshooting
-- https://wezfurlong.org/wezterm/troubleshooting.html

-- Allow working with both the current release and the nightly
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- https://wezfurlong.org/wezterm/config/fonts.html
-- https://www.jetbrains.com/lp/mono/
-- https://github.com/microsoft/cascadia-code
-- https://github.com/tonsky/FiraCode
-- https://github.com/adobe-fonts/source-code-pro

config.font_size = 12

-- config.disable_default_key_bindings = true
config.hide_tab_bar_if_only_one_tab = true
-- https://wezfurlong.org/wezterm/config/lua/config/debug_key_events.html
config.debug_key_events = false

-- config.color_scheme = 'AdventureTime'
-- config.color_scheme = 'rose-pine'
-- config.color_scheme = 'Dracula (Gogh)'
-- config.color_scheme = 'Gruvbox (Gogh)'
-- config.color_scheme = 'Gruvbox Dark (Gogh)'

wezterm.on('gui-startup', function()
  local _, _, window = mux.spawn_window {}
  window:gui_window():maximize()
end)
-- https://wezfurlong.org/wezterm/faq.html?h=path#im-on-macos-and-wezterm-cannot-find-things-in-my-path
if platform.is_mac then
  config.set_environment_variables = {
    PATH = table.concat({
      wezterm.home_dir .. '/.cargo/bin',
      os.getenv 'PATH',
    }, ':'),
    -- prepend the path to custom binaries
  }
end

local launch_menu = {}
if platform.is_win then
  -- wezterm.log_info 'on windows'
  config.default_prog = { wezterm.home_dir .. '/bin/nu' }
  launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { wezterm.home_dir .. '/bin/nu' } },
  }
else
  -- wezterm.log_info 'on mac or linux'
  config.default_prog = { wezterm.home_dir .. '/bin/nu' }
  launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { wezterm.home_dir .. '/bin/nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end
config.launch_menu = launch_menu

-- Styling Inactive Panes
config.inactive_pane_hsb = {
  saturation = 0.5, -- smaller values can make it appear more washed out
  brightness = 0.8, -- dims or increases the perceived amount of light
}

config.mouse_bindings = {
  --   -- https://dystroy.org/blog/from-terminator-to-wezterm/
  --   -- Disable the default click behavior
  --   {
  --     event = { Up = { streak = 1, button = 'Left' } },
  --     mods = 'NONE',
  --     action = w.action.DisableDefaultAssignment,
  --   },
  --   -- Ctrl-click will open the link under the mouse cursor
  --   {
  --     event = { Up = { streak = 1, button = 'Left' } },
  --     mods = 'CTRL',
  --     action = w.action.OpenLinkAtMouseCursor,
  --   },
  --   -- Disable the Ctrl-click down event to stop programs from seeing it when a URL is clicked
  --   {
  --     event = { Down = { streak = 1, button = 'Left' } },
  --     mods = 'CTRL',
  --     action = w.action.Nop,
  --   },
  --   {
  --     event = { Down = { streak = 3, button = 'Left' } },
  --     action = w.action.SelectTextAtMouseCursor 'SemanticZone',
  --     mods = 'NONE',
  --   },
}

config.keys = {

  { key = '0', mods = 'ALT', action = wezterm.action.ResetFontSize },
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  -- { key = 'd',   mods = 'ALT',        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = 'CTRL', action = act.SendKey { key = ' ', mods = 'CTRL' } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },

  -- Main bidings
  { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
  { key = '-', mods = 'ALT', action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = '\\', mods = 'ALT', action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'a', mods = 'ALT', action = act.ActivateCommandPalette }, -- [c]ommands
  { key = 'c', mods = 'ALT', action = act.ActivateCopyMode }, -- [C]opy
  { key = 'd', mods = 'ALT', action = act.ShowDebugOverlay },
  { key = 'f', mods = 'ALT', action = act.Search { CaseInSensitiveString = '' } }, -- [f]ind
  { key = 'r', mods = 'ALT', action = act.RotatePanes 'Clockwise' }, -- [r]otate panes
  { key = 'r', mods = 'CTRL|ALT', action = act.RotatePanes 'CounterClockwise' }, -- [r]otate panes counter clockwise
  { key = 's', mods = 'ALT', action = act.PaneSelect { mode = 'SwapWithActive' } }, -- [s]wap pane with another one
  { key = 'u', mods = 'ALT', action = act.CharSelect }, -- insert [u]nicode character, e.g. emoji

  -- Workspaces (alt + shift)
  { key = 'D', mods = 'ALT|SHIFT', action = act.SwitchToWorkspace { name = 'default' } }, -- switch to the [d]efault workspace
  { key = 'A', mods = 'ALT|SHIFT', action = act.SwitchToWorkspace }, -- [a]dd a new workspace with a random name and switch to it
  { key = 'W', mods = 'ALT|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } }, -- fuzzy search or create new [w]orkspace
  { key = 'N', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(1) }, -- [n]ext
  { key = 'P', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(-1) }, -- [p]revious
  { key = 'S', mods = 'ALT|SHIFT', action = wezterm.action_callback(workspace_sessionizer.start) }, -- open new session

  { key = 'O', mods = 'ALT|SHIFT', action = wezterm.action.ToggleAlwaysOnBottom },
  { key = 'T', mods = 'ALT|SHIFT', action = wezterm.action.ToggleAlwaysOnTop },
  -- https://wezfurlong.org/wezterm/config/lua/keyassignment/ScrollToPrompt.html
  -- This action operates on Semantic Zones defined by applications that use OSC 133 Semantic Prompt Escapes and requires configuring your shell to emit those sequences.
  -- OSC 133 escapes allow marking regions of output as Output (from the commands that you run), Input (that you type) and Prompt ("chrome" from your shell).
  -- { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  -- { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },

  -- open config file
  {
    key = ',',
    mods = 'ALT',
    action = act.SwitchToWorkspace {
      name = 'wezterm-config',
      spawn = {
        cwd = os.getenv 'WEZTERM_CONFIG_DIR',
        args = { 'nu', '-e', 'nvim $env.WEZTERM_CONFIG_FILE' },
      },
    },
  },

  -- Window
  { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },

  { key = 'Enter', mods = 'ALT', action = act.DisableDefaultAssignment }, -- broot uses alt-enter

  -- adjust panes
  { key = 'H', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'L', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'J', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'K', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 3 } },

  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } }, -- forced close pane
  { key = 'q', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } }, -- forced close pane

  { key = 'n', mods = 'ALT', action = act.ActivatePaneDirection 'Next' },
  { key = 'p', mods = 'ALT', action = act.ActivatePaneDirection 'Prev' },

  -- Cli apps
  -- lagy[g]it
  { key = 'g', mods = 'ALT', action = act.SplitHorizontal { args = { 'nu', '-e', 'lazygit' } } },
  { key = 'g', mods = 'CTRL|ALT', action = act.SplitVertical { args = { 'nu', '-e', 'lazygit' } } },
  -- open broot, alt-x to close pane, ctrl-c to go back to shell
  { key = 'b', mods = 'ALT', action = act.SplitHorizontal { args = { 'nu', '-e', 'br' } } },
  { key = 'b', mods = 'CTRL|ALT', action = act.SplitVertical { args = { 'nu', '-e', 'br' } } },

  {
    key = 't',
    mods = 'ALT',
    action = act.SwitchToWorkspace {
      name = 'todos',
      spawn = {
        cwd = zettelkasten,
        args = { 'nu', '-e', 'nvim ' .. zettelkasten .. 'todos.md' },
      },
    },
  },

  -- wezterm k[e]y bindings
  { key = 'e', mods = 'ALT', action = act.SplitHorizontal { args = { 'nu', '-e', 'wezterm show-keys | nvim ' } } },
  --m[o]nitoring
  { key = 'm', mods = 'ALT', action = act.SwitchToWorkspace { name = 'monitoring', spawn = { args = { 'btm' } } } },
}

config.switch_to_last_active_tab_when_closing_tab = true
config.exit_behavior = 'CloseOnCleanExit'

config.hyperlink_rules = {
  -- Matches: a URL in parens: (URL)
  { regex = '\\((\\w+://\\S+)\\)', format = '$1', highlight = 1 },
  -- Matches: a URL in brackets: [URL]
  { regex = '\\[(\\w+://\\S+)\\]', format = '$1', highlight = 1 },
  -- Matches: a URL in curly braces: {URL}
  { regex = '\\{(\\w+://\\S+)\\}', format = '$1', highlight = 1 },
  -- Matches: a URL in angle brackets: <URL>
  { regex = '<(\\w+://\\S+)>', format = '$1', highlight = 1 },

  -- Matches:  numbers
  {
    regex = '(\\d+)',
    format = 'https://mbbm-ast.visualstudio.com/AST/_workitems/edit/$1',
    highlight = 1,
  },
  -- Then handle URLs not wrapped in brackets
  { regex = '[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)', format = '$1', highlight = 1 },
  -- implicit mailto link
  { regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b', format = 'mailto:$0', highlight = 1 },
}

return config
