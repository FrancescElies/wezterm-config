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
    { label = 'PowerShell Core',    args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt',     args = { 'cmd' } },
    { label = 'Nushell',            args = { 'nu' } },
  }
elseif platform.is_mac then
  w.log_info 'on mac'
  config.default_prog = { home .. '/.cargo/bin/nu' }
  config.launch_menu = {
    { label = 'Bash',    args = { 'bash' } },
    { label = 'Nushell', args = { '~/.cargo/bin/nu' } },
    { label = 'Zsh',     args = { 'zsh' } },
  }
end

local mods = {
  shift_ctrl = 'SHIFT|CTRL',
  -- linux & windows (for mac continue reading)
  shift_alt = 'SHIFT|ALT',
  alt = 'ALT',
  ctrl = 'CTRL',
  alt_ctrl = 'ALT|CTRL',
} -- modifier keys

if platform.is_mac then
  mods.shift_alt = 'SHIFT|SUPER'
  mods.alt = 'SUPER'
  mods.alt_ctrl = 'SUPER|CTRL'
end

local function is_vim(window)
  local function process_is_vim(process_info)
    w.log_info('process: ' .. process_info.name)
    return string.find(process_info.name, 'nvim')
  end
  -- check current process
  local p = mux.get_window(window:window_id()):active_pane():get_foreground_process_info()
  for i = 1, 10, 1 do
    if p == nil then
      return false
    end

    if process_is_vim(p) then
      return true
    end
    -- check parent process in the next iteration
    p = w.procinfo.get_info_for_pid(p.ppid)
  end

  return false
end

---
---@param window
---@param pane
---@param action_wez string executed when the active pane is not a nvim instance
---@param forward_key_nvim string key combination forwarded to nvim if the active pane is a nvim instance
local function wez_nvim_action(window, pane, action_wez, forward_key_nvim)
  if is_vim(window) then
    window:perform_action(forward_key_nvim, pane)
  else
    window:perform_action(action_wez, pane)
  end
end

-- keep in sync with nvim wezterm.lua
local move_map = {
  { wez_action_name = 'move-left',  wez_action = act.ActivatePaneDirection 'Left',  key = 'h', mods = mods.alt },
  { wez_action_name = 'move-right', wez_action = act.ActivatePaneDirection 'Right', key = 'l', mods = mods.alt },
  { wez_action_name = 'move-up',    wez_action = act.ActivatePaneDirection 'Up',    key = 'k', mods = mods.alt },
  { wez_action_name = 'move-down',  wez_action = act.ActivatePaneDirection 'Down',  key = 'j', mods = mods.alt },
}

for _, v in pairs(move_map) do
  w.on(v.wez_action_name, function(window, pane)
    wez_nvim_action(window, pane, v.wez_action, act.SendKey { key = v.key, mods = v.mods })
  end)
end

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
w.on('close-pane', function(window, pane)
  wez_nvim_action(window, pane, act.CloseCurrentPane { confirm = false }, act.SendKey { key = 'x', mods = mods.alt })
end)

config.keys = {
  { key = 'z',   mods = mods.shift_ctrl, action = act.TogglePaneZoomState },
  { key = 'f',   mods = mods.alt,        action = act.TogglePaneZoomState },
  { key = ' ',   mods = mods.ctrl,       action = 'DisableDefaultAssignment' },
  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ',   mods = mods.ctrl,       action = act.SendKey { key = ' ', mods = mods.ctrl } },
  { key = 'F1',  mods = 'NONE',          action = act.ActivateCopyMode },
  { key = 'F12', mods = 'NONE',          action = act.ShowDebugOverlay },
  { key = 'a',   mods = mods.alt,        action = act.ShowLauncher },
  {
    key = '-',
    mods = mods.alt,
    action = act {
      SplitVertical = { domain = 'CurrentPaneDomain' },
    },
  },
  {
    key = '\\',
    mods = mods.alt,
    action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } },
  },

  { key = 'Enter', mods = mods.alt,       action = act.DisableDefaultAssignment }, -- broot uses alt-enter

  { key = 's',     mods = mods.alt,       action = act.PaneSelect { alphabet = '1234567890' } },
  { key = 'r',     mods = mods.alt,       action = act 'ReloadConfiguration' },

  -- adjust panes
  { key = 'h',     mods = mods.shift_alt, action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'l',     mods = mods.shift_alt, action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'j',     mods = mods.shift_alt, action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'k',     mods = mods.shift_alt, action = act.AdjustPaneSize { 'Up', 3 } },

  -- move between neovim and wezterm panes
  { key = 'h',     mods = mods.alt,       action = w.action { EmitEvent = 'move-left' } },
  { key = 'l',     mods = mods.alt,       action = w.action { EmitEvent = 'move-right' } },
  { key = 'j',     mods = mods.alt,       action = w.action { EmitEvent = 'move-down' } },
  { key = 'k',     mods = mods.alt,       action = w.action { EmitEvent = 'move-up' } },
  { key = 'x',     mods = mods.alt,       action = w.action { EmitEvent = 'close-pane' } },
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
}

return config
