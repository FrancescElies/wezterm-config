-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm

local w = require 'wezterm'

local home = os.getenv 'HOME'

local platform = {
  is_win = string.find(w.target_triple, 'windows') ~= nil,
  is_linux = string.find(w.target_triple, 'linux') ~= nil,
  is_mac = string.find(w.target_triple, 'apple') ~= nil,
}

local options = {
  default_prog = {},
  launch_menu = {},
}

if platform.is_win then
  options.default_prog = { 'nu' }
  options.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { 'nu' } },
  }
elseif platform.is_mac then
  options.default_prog = { home .. '/.cargo/bin/nu' }
  options.launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { '~/.cargo/bin/nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end

local mod = {} -- modifier keys

if platform.is_mac then
  mod.super_or_alt = 'SUPER'
  mod.super_or_alt_ctrl = 'SUPER|CTRL'
elseif platform.is_win then
  mod.super_or_alt = 'ALT' -- to not conflict with Windows key shortcuts
  mod.super_or_alt_ctrl = 'ALT|CTRL'
end

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = {
  Left = 'h',
  Down = 'j',
  Up = 'k',
  Right = 'l',
  -- reverse lookup
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = w.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'META' or 'CTRL' },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

return {
  keys = {
    { key = 'F1', mods = 'NONE', action = w.action.ActivateCopyMode },
    { key = 'F12', mods = 'NONE', action = w.action.ShowDebugOverlay },
    { key = 'a', mods = mod.super_or_alt, action = w.action.ShowLauncher },
    {
      key = '-',
      mods = mod.super_or_alt,
      action = w.action {
        SplitVertical = { domain = 'CurrentPaneDomain' },
      },
    },
    {
      key = '\\',
      mods = mod.super_or_alt,
      action = w.action { SplitHorizontal = { domain = 'CurrentPaneDomain' } },
    },

    { key = 'Enter', mods = mod.super_or_alt, action = w.action.DisableDefaultAssignment }, -- broot uses alt-enter
    { key = 's', mods = mod.super_or_alt, action = w.action.PaneSelect { alphabet = '1234567890' } },
    { key = 'r', mods = mod.super_or_alt, action = w.action 'ReloadConfiguration' },
    { key = 'q', mods = mod.super_or_alt, action = w.action { CloseCurrentPane = { confirm = true } } },
    { key = 'x', mods = mod.super_or_alt, action = w.action { CloseCurrentPane = { confirm = true } } },

    -- move between split panes
    split_nav('move', 'h'),
    split_nav('move', 'j'),
    split_nav('move', 'k'),
    split_nav('move', 'l'),
    -- resize panes
    split_nav('resize', 'h'),
    split_nav('resize', 'j'),
    split_nav('resize', 'k'),
    split_nav('resize', 'l'),
  },
  default_prog = options.default_prog,
  launch_menu = options.launch_menu,
}
