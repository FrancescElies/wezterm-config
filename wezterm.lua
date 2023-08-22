-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local w = require 'wezterm'

local home = os.getenv 'HOME'

local platform = {
  is_win = string.find(w.target_triple, 'windows') ~= nil,
  is_linux = string.find(w.target_triple, 'linux') ~= nil,
  is_mac = string.find(w.target_triple, 'apple') ~= nil,
}

local config = {}

if platform.is_win then
  config.default_prog = { 'nu' }
  config.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { 'nu' } },
  }
elseif platform.is_mac then
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
    mods = resize_or_move == 'resize' and mod.alt or mod.ctrl,
    action = w.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and mod.alt or mod.ctrl },
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

config.keys = {
  { key = 'z', mods = mod.shift_ctrl, action = w.action.TogglePaneZoomState },
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
  { key = 'x', mods = mod.alt, action = w.action { CloseCurrentPane = { confirm = true } } },

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
}

config.switch_to_last_active_tab_when_closing_tab = true
config.exit_behavior = 'CloseOnCleanExit'
config.window_close_confirmation = 'AlwaysPrompt'

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
  -- github
  {
    regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
    format = 'https://github.com/$1/$3',
  },
}

return config
