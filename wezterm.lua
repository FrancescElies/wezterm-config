-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local w = require 'wezterm'
local act = require('wezterm').action
local mux = require('wezterm').mux

local home = os.getenv 'HOME'

local platform = {
  is_win = string.find(w.target_triple, 'windows') ~= nil,
  is_linux = string.find(w.target_triple, 'linux') ~= nil,
  is_mac = string.find(w.target_triple, 'apple') ~= nil,
}

local config = {
  debug_key_events = false,
}

if platform.is_win then
  w.log_info 'on windows'
  config.default_prog = { 'nu' }
  config.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { 'nu' } },
  }
elseif platform.is_mac then
  w.log_info 'on mac'
  config.default_prog = { home .. '/.cargo/bin/nu' }
  config.launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { '~/.cargo/bin/nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end

local mod = {
  shift_ctrl = 'SHIFT|CTRL',
  -- linux & windows (for mac continue reading)
  alt = 'ALT',
  ctrl = 'CTRL',
  alt_ctrl = 'ALT|CTRL',
} -- modifier keys

if platform.is_mac then
  mod.alt = 'SUPER'
  mod.alt_ctrl = 'SUPER|CTRL'
end

local mod_window = 'CTRL'
local wez_nvim_action = function(window, pane, action_wez, forward_key_nvim)
  local current_process = mux.get_window(window:window_id()):active_pane():get_foreground_process_name()
  w.log_info(current_process)

  if string.find(current_process, 'nvim') then
    w.log_info 'change window nvim'
    window:perform_action(forward_key_nvim, pane)
  else
    w.log_info 'change window wezterm'
    window:perform_action(action_wez, pane)
  end
end

w.on('move-left', function(window, pane)
  wez_nvim_action(
    window,
    pane,
    act.ActivatePaneDirection 'Left', -- this will execute when the active pane is not a nvim instance
    act.SendKey { key = 'h', mods = mod_window } -- this key combination will be forwarded to nvim if the active pane is a nvim instance
  )
end)

w.on('move-right', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Right', act.SendKey { key = 'l', mods = mod_window })
end)

w.on('move-down', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Down', act.SendKey { key = 'j', mods = mod_window })
end)

w.on('move-up', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Up', act.SendKey { key = 'k', mods = mod_window })
end)

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
w.on('close-pane', function(window, pane)
  wez_nvim_action(window, pane, act.CloseCurrentPane { confirm = false }, act.SendKey { key = 'x', mods = 'ALT' })
end)

config.keys = {
  { key = 'z', mods = mod.shift_ctrl, action = w.action.TogglePaneZoomState },
  { key = ' ', mods = mod.ctrl, action = 'DisableDefaultAssignment' },
  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = mod.ctrl, action = w.action.SendKey { key = ' ', mods = mod.ctrl } },
  { key = 'F1', mods = 'NONE', action = w.action.ActivateCopyMode },
  { key = 'F12', mods = 'NONE', action = w.action.ShowDebugOverlay },
  { key = 'a', mods = mod.alt, action = w.action.ShowLauncher },
  {
    key = '-',
    mods = mod.alt,
    action = w.action {
      SplitVertical = { domain = 'CurrentPaneDomain' },
    },
  },
  {
    key = '\\',
    mods = mod.alt,
    action = w.action { SplitHorizontal = { domain = 'CurrentPaneDomain' } },
  },

  { key = 'Enter', mods = mod.alt, action = w.action.DisableDefaultAssignment }, -- broot uses alt-enter

  { key = 's', mods = mod.alt, action = w.action.PaneSelect { alphabet = '1234567890' } },
  { key = 'r', mods = mod.alt, action = w.action 'ReloadConfiguration' },
  { key = 'q', mods = mod.alt, action = w.action { CloseCurrentPane = { confirm = true } } },

  -- window movements
  { key = 'h', mods = mod_window, action = w.action { EmitEvent = 'move-left' } },
  { key = 'l', mods = mod_window, action = w.action { EmitEvent = 'move-right' } },
  { key = 'j', mods = mod_window, action = w.action { EmitEvent = 'move-down' } },
  { key = 'k', mods = mod_window, action = w.action { EmitEvent = 'move-up' } },
  { key = 'x', mods = mod.alt, action = w.action { EmitEvent = 'close-pane' } },
}

config.switch_to_last_active_tab_when_closing_tab = true
config.exit_behavior = 'CloseOnCleanExit'

config.hyperlink_rules = {
  -- Matches: a URL in parens: (URL)
  {
    regex = '\\((\\w+://\\S+)\\)',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in brackets: [URL]
  {
    regex = '\\[(\\w+://\\S+)\\]',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in curly braces: {URL}
  {
    regex = '\\{(\\w+://\\S+)\\}',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in angle brackets: <URL>
  {
    regex = '<(\\w+://\\S+)>',
    format = '$1',
    highlight = 1,
  },
  -- Then handle URLs not wrapped in brackets
  {
    -- Before
    --regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
    --format = '$0',
    -- After
    regex = '[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)',
    format = '$1',
    highlight = 1,
  },
  -- implicit mailto link
  {
    regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
    format = 'mailto:$0',
  },
  -- -- github
  -- {
  --   regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  --   format = 'https://github.com/$1/$3',
  -- },
}

return config
