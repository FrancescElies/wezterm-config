-- https://wezfurlong.org/wezterm/config/lua/keyassignment/
-- https://wezfurlong.org/wezterm/config/default-keys.html
-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm
-- https://github.com/wez/wezterm/discussions/2329

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local w = require 'wezterm'
local sessionizer = require 'sessionizer'
local utils = require 'utils'
local platform = require 'platform'
local a = w.action
local mux = w.mux

local file_exists = utils.file_exists
local todos_dir = w.home_dir .. '/src/zettelkasten'

local config = {
  hide_tab_bar_if_only_one_tab = true,
  debug_key_events = false,
  font_size = 10,
  -- no need to specify fon
  -- font = w.font 'Fira Code',
}

-- https://wezfurlong.org/wezterm/faq.html?h=path#im-on-macos-and-wezterm-cannot-find-things-in-my-path
if platform.is_mac then
  config.set_environment_variables = {
    PATH = table.concat({
      w.home_dir .. '/.cargo/bin',
      os.getenv 'PATH',
    }, ':'),
    -- prepend the path to custom binaries
  }
end

local home = utils.normalize_path(w.home_dir)
local nushell = (
  file_exists(home .. '/bin/nu')
  or file_exists(home .. '/.cargo/bin/nu')
  -- windows
  or file_exists(home .. '/bin/nu.exe')
  or file_exists(home .. '/.cargo/bin/nu.exe')
)

if platform.is_win then
  w.log_info 'on windows'
  config.default_prog = { w.home_dir .. '/bin/nu' }
  config.launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { w.home_dir .. '/bin/nu' } },
  }
else
  w.log_info 'on mac or linux'
  config.default_prog = { w.home_dir .. '/bin/nu' }
  config.launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { w.home_dir .. '/bin/nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end

-- default modifier keys
local mods = {
  shift_ctrl = 'SHIFT|CTRL',
  shift_alt = 'SHIFT|ALT',
  alt = 'ALT',
  ctrl = 'CTRL',
  alt_ctrl = 'ALT|CTRL',
}

-- NOTE: SUPER (CMD) is currently (25.11.2023) difficult to bind in nvim
-- mac modifier keys
-- if platform.is_mac then
--   mods.shift_alt = 'SHIFT|SUPER'
--   mods.alt = 'SUPER'
--   mods.alt_ctrl = 'SUPER|CTRL'
-- end

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

local function wez_nvim_action(window, pane, action_wez, forward_key_nvim)
  if is_vim(window) then
    window:perform_action(forward_key_nvim, pane)
  else
    window:perform_action(action_wez, pane)
  end
end

-- keep in sync with nvim wezterm.lua
local move_map = {
  { wez_action_name = 'move-left', wez_action = a.ActivatePaneDirection 'Left', key = 'h', mods = mods.alt },
  { wez_action_name = 'move-right', wez_action = a.ActivatePaneDirection 'Right', key = 'l', mods = mods.alt },
  { wez_action_name = 'move-up', wez_action = a.ActivatePaneDirection 'Up', key = 'k', mods = mods.alt },
  { wez_action_name = 'move-down', wez_action = a.ActivatePaneDirection 'Down', key = 'j', mods = mods.alt },
}

for _, v in pairs(move_map) do
  w.on(v.wez_action_name, function(window, pane) wez_nvim_action(window, pane, v.wez_action, a.SendKey { key = v.key, mods = v.mods }) end)
end

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
w.on('close-pane', function(window, pane) wez_nvim_action(window, pane, a.CloseCurrentPane { confirm = false }, a.SendKey { key = 'x', mods = mods.alt }) end)

config.mouse_bindings = {
  -- https://dystroy.org/blog/from-terminator-to-wezterm/
  -- Disable the default click behavior
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = w.action.DisableDefaultAssignment,
  },
  -- Ctrl-click will open the link under the mouse cursor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = w.action.OpenLinkAtMouseCursor,
  },
  -- Disable the Ctrl-click down event to stop programs from seeing it when a URL is clicked
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = w.action.Nop,
  },
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = w.action.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

config.keys = {

  { key = 'z', mods = mods.alt, action = a.TogglePaneZoomState },
  -- { key = 'd',   mods = mods.alt,        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = mods.ctrl, action = a.SendKey { key = ' ', mods = mods.ctrl } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },
  { key = 'x', mods = mods.shift_ctrl, action = a.ActivateCopyMode },
  { key = 'c', mods = mods.alt, action = a.ActivateCopyMode },
  { key = 'F12', mods = 'NONE', action = a.ShowDebugOverlay },
  { key = 'a', mods = mods.alt, action = a.ShowLauncher },

  -- Workspaces
  { key = 'w', mods = mods.alt, action = a.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 's', mods = mods.alt, action = w.action_callback(sessionizer.start) },
  { key = 'n', mods = mods.alt, action = a.SwitchWorkspaceRelative(1) },
  { key = 'p', mods = mods.alt, action = a.SwitchWorkspaceRelative(-1) },
  { key = 'N', mods = mods.alt, action = a.SwitchToWorkspace },

  -- Cli apps
  -- [f]ind (broot)
  { key = 'f', mods = mods.alt, action = a.SplitVertical { args = { 'broot' } } },
  { key = 'f', mods = mods.shift_alt, action = a.SplitHorizontal { args = { 'broot' } } },
  -- lagy[g]it
  { key = 'g', mods = mods.alt, action = a.SplitVertical { args = { 'lazygit' } } },
  { key = 'g', mods = mods.shift_alt, action = a.SplitHorizontal { args = { 'lazygit' } } },
  -- [t]odos
  { key = 't', mods = mods.alt, action = a.SplitVertical { args = { 'broot', todos_dir } } },
  { key = 't', mods = mods.shift_alt, action = a.SplitHorizontal { args = { 'broot', todos_dir } } },
  --b[o]ttom
  { key = 'o', mods = mods.alt, action = a.SplitVertical { args = { 'btm' } } },
  { key = 'o', mods = mods.shift_alt, action = a.SplitHorizontal { args = { 'btm' } } },
  -- d[i]skonaut
  { key = 'i', mods = mods.alt, action = a.SplitVertical { args = { 'diskonaut' } } },
  { key = 'i', mods = mods.shift_alt, action = a.SplitHorizontal { args = { 'diskonaut' } } },

  -- Window
  { key = 'F11', mods = 'NONE', action = a.ToggleFullScreen },

  { key = 'Enter', mods = mods.alt, action = a.DisableDefaultAssignment }, -- broot uses alt-enter

  -- Panes
  { key = '-', mods = mods.alt, action = a { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = '\\', mods = mods.alt, action = a { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'r', mods = mods.alt, action = a.ReloadConfiguration },

  -- adjust panes
  { key = 'h', mods = mods.shift_alt, action = a.AdjustPaneSize { 'Left', 3 } },
  { key = 'l', mods = mods.shift_alt, action = a.AdjustPaneSize { 'Right', 3 } },
  { key = 'j', mods = mods.shift_alt, action = a.AdjustPaneSize { 'Down', 3 } },
  { key = 'k', mods = mods.shift_alt, action = a.AdjustPaneSize { 'Up', 3 } },

  -- move between neovim and wezterm panes
  { key = 'h', mods = mods.alt, action = w.action { EmitEvent = 'move-left' } },
  { key = 'l', mods = mods.alt, action = w.action { EmitEvent = 'move-right' } },
  { key = 'j', mods = mods.alt, action = w.action { EmitEvent = 'move-down' } },
  { key = 'k', mods = mods.alt, action = w.action { EmitEvent = 'move-up' } },
  { key = 'x', mods = mods.alt, action = w.action { EmitEvent = 'close-pane' } },
  { key = 'd', mods = mods.alt, action = w.action { EmitEvent = 'close-pane' } },
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

  -- Matches:  "pullRequestId": 6571
  {
    regex = '"pullRequestId": (\\d+)',
    format = 'https://mbbm-ast.visualstudio.com/AST/_git/eklang/pullrequest/$1',
    highlight = 1,
  },
  -- Then handle URLs not wrapped in brackets
  { regex = '[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)', format = '$1', highlight = 1 },
  -- implicit mailto link
  { regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b', format = 'mailto:$0', highlight = 1 },
}

return config
