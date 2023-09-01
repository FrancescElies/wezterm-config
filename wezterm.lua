-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local wezterm = require 'wezterm'
local act = require('wezterm').action
local mux = require('wezterm').mux

local home = os.getenv 'HOME'

local platform = {
  is_win = string.find(wezterm.target_triple, 'windows') ~= nil,
  is_linux = string.find(wezterm.target_triple, 'linux') ~= nil,
  is_mac = string.find(wezterm.target_triple, 'apple') ~= nil,
}

local config = {
  debug_key_events = false,
}

if platform.is_win then
  wezterm.log_info 'on windows'
  config.default_prog = { 'nu' }
  config.launch_menu = {
    { label = 'PowerShell Core',    args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt',     args = { 'cmd' } },
    { label = 'Nushell',            args = { 'nu' } },
  }
elseif platform.is_mac then
  wezterm.log_info 'on mac'
  config.default_prog = { home .. '/.cargo/bin/nu' }
  config.launch_menu = {
    { label = 'Bash',    args = { 'bash' } },
    { label = 'Nushell', args = { '~/.cargo/bin/nu' } },
    { label = 'Zsh',     args = { 'zsh' } },
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

local mod_pane_move = 'CTRL'

local function is_nvim(window)
  local current_process = mux.get_window(window:window_id()):active_pane():get_foreground_process_name()
  wezterm.log_info(current_process)
  if platform.is_win then
    return string.find(current_process, 'nvim')
  else
    local nvim = '/usr/bin/nvim' -- change this to the location of you nvim
    return current_process == nvim
  end
end

--- Cahanges wezterm pane or nvim pane acording to where you are.
---@param window Window
---@param pane Pane
---@param action_wez act.ActivatePaneDirection will execute when the active pane is not a nvim instance
---@param forward_key_nvim act.SendKey key combination will be forwarded to nvim if the active pane is a nvim instance
local function wez_nvim_action(window, pane, action_wez, forward_key_nvim)
  if is_nvim(window) then
    window:perform_action(forward_key_nvim, pane)
  else
    window:perform_action(action_wez, pane)
  end
end

wezterm.on('move-left', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Left', act.SendKey { key = 'h', mods = mod_pane_move })
end)

wezterm.on('move-right', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Right', act.SendKey { key = 'l', mods = mod_pane_move })
end)

wezterm.on('move-down', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Down', act.SendKey { key = 'j', mods = mod_pane_move })
end)

wezterm.on('move-up', function(window, pane)
  wez_nvim_action(window, pane, act.ActivatePaneDirection 'Up', act.SendKey { key = 'k', mods = mod_pane_move })
end)

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
wezterm.on('close-pane', function(window, pane)
  wez_nvim_action(window, pane, act.CloseCurrentPane { confirm = false }, act.SendKey { key = 'x', mods = 'ALT' })
end)

config.keys = {
  { key = 'z',   mods = mod.shift_ctrl, action = act.TogglePaneZoomState },
  { key = ' ',   mods = mod.ctrl,       action = 'DisableDefaultAssignment' },
  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ',   mods = mod.ctrl,       action = act.SendKey { key = ' ', mods = mod.ctrl } },
  { key = 'F1',  mods = 'NONE',         action = act.ActivateCopyMode },
  { key = 'F12', mods = 'NONE',         action = act.ShowDebugOverlay },
  { key = 'a',   mods = mod.alt,        action = act.ShowLauncher },
  {
    key = '-',
    mods = mod.alt,
    action = act {
      SplitVertical = { domain = 'CurrentPaneDomain' },
    },
  },
  {
    key = '\\',
    mods = mod.alt,
    action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } },
  },

  { key = 'Enter', mods = mod.alt,       action = act.DisableDefaultAssignment }, -- broot uses alt-enter

  { key = 's',     mods = mod.alt,       action = act.PaneSelect { alphabet = '1234567890' } },
  { key = 'r',     mods = mod.alt,       action = act 'ReloadConfiguration' },
  { key = 'q',     mods = mod.alt,       action = act { CloseCurrentPane = { confirm = true } } },

  -- window movements
  { key = 'h',     mods = mod_pane_move, action = act { EmitEvent = 'move-left' } },
  { key = 'l',     mods = mod_pane_move, action = act { EmitEvent = 'move-right' } },
  { key = 'j',     mods = mod_pane_move, action = act { EmitEvent = 'move-down' } },
  { key = 'k',     mods = mod_pane_move, action = act { EmitEvent = 'move-up' } },
  { key = 'x',     mods = mod.alt,       action = act { EmitEvent = 'close-pane' } },
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
