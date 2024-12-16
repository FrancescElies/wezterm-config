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
local tab_bar = require 'tab_bar'
local apps = require 'apps'
local act = wezterm.action
local mux = wezterm.mux
local io = require 'io'
local os = require 'os'

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

config.disable_default_key_bindings = true
-- config.hide_tab_bar_if_only_one_tab = true
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
      wezterm.home_dir .. '/bin',
      '/opt/homebrew/bin',
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
  config.default_prog = { 'nu' }
  launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { 'nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end
config.launch_menu = launch_menu

-- Styling Inactive Panes
config.inactive_pane_hsb = {
  saturation = 0.9, -- smaller values can make it appear more washed out
  brightness = 0.7, -- dims or increases the perceived amount of light
}

-- https://wezfurlong.org/wezterm/config/lua/wezterm/on.html#custom-events
wezterm.on('trigger-nvim-with-scrollback', function(window, pane)
  -- Retrieve the text from the pane
  local text = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)

  -- Create a temporary file to pass to vim
  local name = os.tmpname()
  local f = io.open(name, 'w+')
  if f == nil then
    wezterm.log_error('failed to open ' .. name)
    return
  end
  f:write(text)
  f:flush()
  f:close()

  window:perform_action(act.SplitHorizontal { args = { 'nu', '-e', 'nvim ' .. name } }, pane)

  -- Wait "enough" time for vim to read the file before we remove it.
  -- The window creation and process spawn are asynchronous wrt. running
  -- this script and are not awaitable, so we just pick a number.
  --
  -- Note: We don't strictly need to remove this file, but it is nice
  -- to avoid cluttering up the temporary directory.
  wezterm.sleep_ms(1000)
  os.remove(name)
end)

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
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

config.keys = {

  { key = '0', mods = 'ALT', action = wezterm.action.ResetFontSize },
  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  -- { key = 'd',   mods = 'ALT',        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = 'CTRL', action = act.SendKey { key = ' ', mods = 'CTRL' } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },

  -- Main bidings
  { key = 'F9', mods = 'ALT|SHIFT', action = wezterm.action.ToggleAlwaysOnBottom },
  { key = 'F10', mods = 'ALT|SHIFT', action = wezterm.action.ToggleAlwaysOnTop },
  { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },

  { key = '-', mods = 'ALT', action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = 's', mods = 'ALT', action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = '\\', mods = 'ALT', action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'v', mods = 'ALT', action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'a', mods = 'ALT', action = act.ActivateCommandPalette }, -- [c]ommands
  { key = 'c', mods = 'ALT', action = act.ActivateCopyMode }, -- [C]opy
  { key = 'd', mods = 'ALT', action = act.ShowDebugOverlay },
  { key = 'f', mods = 'ALT', action = act.Search { CaseInSensitiveString = '' } }, -- [f]ind
  { key = 'r', mods = 'ALT', action = act.RotatePanes 'Clockwise' }, -- [r]otate panes
  { key = 'r', mods = 'CTRL|ALT', action = act.RotatePanes 'CounterClockwise' }, -- [r]otate panes counter clockwise
  { key = 'w', mods = 'ALT', action = act.PaneSelect { mode = 'SwapWithActive' } }, -- [s]wap pane with another one
  { key = 'u', mods = 'ALT', action = act.CharSelect }, -- insert [u]nicode character, e.g. emoji

  -- Workspaces (alt + shift)
  { key = 'D', mods = 'ALT|SHIFT', action = act.SwitchToWorkspace { name = 'default' } }, -- switch to the [d]efault workspace
  { key = 'S', mods = 'ALT|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } }, -- Go to workspace
  { key = 'I', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = 'O', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(1) },
  { key = 'P', mods = 'ALT|SHIFT', action = wezterm.action_callback(workspace_sessionizer.start) }, -- Open Project

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

  { key = 'x', mods = 'ALT', action = wezterm.action_callback(apps.start) },
  { key = 'q', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },

  { key = 't', mods = 'ALT', action = wezterm.action_callback(function(_, pane) pane:move_to_new_tab() end) },
  { key = 'ı', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = 'i', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = 'o', mods = 'ALT', action = act.ActivateTabRelative(1) },

  { key = 'e', mods = 'ALT', action = act.EmitEvent 'trigger-nvim-with-scrollback' },
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
  -- {
  --   regex = '(\\d+)',
  --   format = 'https://mbbm-ast.visualstudio.com/AST/_workitems/edit/$1',
  --   highlight = 1,
  -- },
  -- Then handle URLs not wrapped in brackets
  { regex = '[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)', format = '$1', highlight = 1 },
  -- implicit mailto link
  { regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b', format = 'mailto:$0', highlight = 1 },
}

return config
