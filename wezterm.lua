-- https://wezfurlong.org/wezterm/config/lua/keyassignment/
-- https://wezfurlong.org/wezterm/config/default-keys.html
-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm
-- https://github.com/wez/wezterm/discussions/2329

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local wezterm = require 'wezterm'
local sessionizer = require 'sessionizer'
local utils = require 'utils'
local platform = require 'platform'
local act = wezterm.action
local mux = wezterm.mux

local file_exists = utils.file_exists
local zettelkasten = wezterm.home_dir .. '/src/zettelkasten/'

local config = {
  hide_tab_bar_if_only_one_tab = true,
  debug_key_events = false,
  -- font_size = 12,
  -- font = w.font 'JetBrains Mono',
}
-- config.color_scheme = 'AdventureTime'
config.color_scheme = 'rose-pine'
-- config.color_scheme = 'Dracula (Gogh)'
-- config.color_scheme = 'Gruvbox (Gogh)'
-- config.color_scheme = 'Gruvbox Dark (Gogh)'

wezterm.on('gui-startup', function()
  local tab, pane, window = mux.spawn_window {}
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

local home = utils.normalize_path(wezterm.home_dir)
local nushell = (
  file_exists(home .. '/bin/nu')
  or file_exists(home .. '/.cargo/bin/nu')
  -- windows
  or file_exists(home .. '/bin/nu.exe')
  or file_exists(home .. '/.cargo/bin/nu.exe')
)

local launch_menu = {}
if platform.is_win then
  wezterm.log_info 'on windows'
  config.default_prog = { wezterm.home_dir .. '/bin/nu' }
  launch_menu = {
    { label = 'PowerShell Core', args = { 'pwsh' } },
    { label = 'PowerShell Desktop', args = { 'powershell' } },
    { label = 'Command Prompt', args = { 'cmd' } },
    { label = 'Nushell', args = { wezterm.home_dir .. '/bin/nu' } },
  }
  -- Find installed visual studio version(s) and add their compilation
  -- environment command prompts to the menu
  wezterm.log_info 'Finding installed visual studio version'
  for _, vsvers in pairs(wezterm.glob('Microsoft Visual Studio/20*', 'C:/Program Files (x86)')) do
    wezterm.log_info(vsvers)
    local year = vsvers:gsub('Microsoft Visual Studio/', '')
    table.insert(launch_menu, {
      label = 'x64 Native Tools VS ' .. year,
      args = {
        'cmd.exe',
        '/k',
        'C:/Program Files (x86)/' .. vsvers .. '/BuildTools/VC/Auxiliary/Build/vcvars64.bat',
      },
    })
  end
  wezterm.log_info 'End of visual studio version'
else
  wezterm.log_info 'on mac or linux'
  config.default_prog = { wezterm.home_dir .. '/bin/nu' }
  launch_menu = {
    { label = 'Bash', args = { 'bash' } },
    { label = 'Nushell', args = { wezterm.home_dir .. '/bin/nu' } },
    { label = 'Zsh', args = { 'zsh' } },
  }
end
config.launch_menu = launch_menu

-- default modifier keys
local mods = {
  ctrl = 'CTRL',
  ctrl_shift = 'SHIFT|CTRL',
  ctrl_alt = 'ALT|CTRL',
  alt = 'ALT',
  alt_shift = 'SHIFT|ALT',
}

-- NOTE: SUPER (CMD) is currently (25.11.2023) difficult to bind in nvim
-- mac modifier keys
-- if platform.is_mac then
--   mods.shift_alt = 'SHIFT|SUPER'
--   mods.alt = 'SUPER'
--   mods.alt_ctrl = 'SUPER|CTRL'
-- end

local function is_vim(window)
  wezterm.log_info 'is vim?'

  local function process_is_vim(process_info) return string.find(process_info.name, 'nvim') end
  -- check current process
  local p = mux.get_window(window:window_id()):active_pane():get_foreground_process_info()
  for i = 1, 10, 1 do
    if process_is_vim(p) then
      return true
    end

    -- quick and dirty 2 level deep check children process for nvim
    -- NOTE: this covers the case where nvim is started from broot
    for child_pid, child in pairs(p.children) do
      wezterm.log_info('child of ' .. p.name .. ': name=' .. child.name .. ' pid=' .. child_pid)
      if process_is_vim(child) then
        return true
      end
      -- for grandchild_pid, grandchild in pairs(child.children) do
      --   w.log_info('child of ' .. child.name .. ': name=' .. grandchild.name .. ' pid=' .. grandchild_pid)
      --   if process_is_vim(grandchild) then
      --     return true
      --   end
      -- end
    end

    -- TODO: check parent processes needed? check windows
    local pp = wezterm.procinfo.get_info_for_pid(p.ppid)
    if pp == nil then
      wezterm.log_info 'parent is nil'
      return false
    else
      wezterm.log_info('parent of ' .. p.name .. ': name=' .. pp.name .. ' pid=' .. pp.pid)
      p = pp
    end
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
  { wez_action_name = 'move-left', wez_action = act.ActivatePaneDirection 'Left', key = 'h', mods = mods.alt },
  { wez_action_name = 'move-right', wez_action = act.ActivatePaneDirection 'Right', key = 'l', mods = mods.alt },
  { wez_action_name = 'move-up', wez_action = act.ActivatePaneDirection 'Up', key = 'k', mods = mods.alt },
  { wez_action_name = 'move-down', wez_action = act.ActivatePaneDirection 'Down', key = 'j', mods = mods.alt },
}

for _, v in pairs(move_map) do
  wezterm.on(v.wez_action_name, function(window, pane) wez_nvim_action(window, pane, v.wez_action, act.SendKey { key = v.key, mods = v.mods }) end)
end

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
wezterm.on(
  'close-pane',
  function(window, pane) wez_nvim_action(window, pane, act.CloseCurrentPane { confirm = false }, act.SendKey { key = 'x', mods = mods.alt }) end
)

-- Styling Inactive Panes
config.inactive_pane_hsb = {
  saturation = 0.3, -- smaller values can make it appear more washed out
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

  { key = 'z', mods = mods.alt, action = act.TogglePaneZoomState },
  -- { key = 'd',   mods = mods.alt,        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = mods.ctrl, action = act.SendKey { key = ' ', mods = mods.ctrl } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },
  { key = 'c', mods = mods.alt, action = act.ActivateCopyMode },
  { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
  { key = 'd', mods = mods.alt, action = act.ShowDebugOverlay },
  { key = 'P', mods = mods.alt_shift, action = act.ActivateCommandPalette },

  -- Workspaces
  { key = 'w', mods = mods.alt, action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } }, -- [w]indow
  { key = 's', mods = mods.alt, action = wezterm.action_callback(sessionizer.start) }, -- [s]witch to workspace
  { key = 'n', mods = mods.alt, action = act.SwitchWorkspaceRelative(1) }, -- [n]ext
  { key = 'p', mods = mods.alt, action = act.SwitchWorkspaceRelative(-1) }, -- [p]revious
  { key = 'N', mods = mods.alt, action = act.SwitchToWorkspace }, -- [n]ew
  { key = 'F', mods = mods.alt_shift, action = act.Search { CaseInSensitiveString = '' } }, -- [f]ind

  -- open config file
  {
    key = ',',
    mods = mods.alt,
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

  { key = 'Enter', mods = mods.alt, action = act.DisableDefaultAssignment }, -- broot uses alt-enter

  -- Panes
  { key = '-', mods = mods.alt, action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = '\\', mods = mods.alt, action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'r', mods = mods.alt, action = act.ReloadConfiguration },

  -- adjust panes
  { key = 'h', mods = mods.alt_shift, action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'l', mods = mods.alt_shift, action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'j', mods = mods.alt_shift, action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'k', mods = mods.alt_shift, action = act.AdjustPaneSize { 'Up', 3 } },

  -- move between neovim and wezterm panes
  { key = 'h', mods = mods.alt, action = act { EmitEvent = 'move-left' } },
  { key = 'l', mods = mods.alt, action = act { EmitEvent = 'move-right' } },
  { key = 'j', mods = mods.alt, action = act { EmitEvent = 'move-down' } },
  { key = 'k', mods = mods.alt, action = act { EmitEvent = 'move-up' } },
  { key = 'x', mods = mods.alt, action = act { EmitEvent = 'close-pane' } },

  -- Cli apps
  -- lagy[g]it
  { key = 'g', mods = mods.alt, action = act.SplitHorizontal { args = { 'lazygit' } } },
  -- [f]iles and folders, alt-x to close pane, ctrl-c to go back to shell
  { key = 'f', mods = mods.alt, action = act.SplitHorizontal { args = { 'nu', '-e', 'br' } } },

  {
    key = 't',
    mods = mods.alt,
    action = act.SwitchToWorkspace {
      name = 'todos',
      spawn = {
        cwd = zettelkasten,
        args = { 'nu', '-e', 'nvim ' .. zettelkasten .. 'todos.md' },
      },
    },
  },
  --m[o]nitoring
  { key = 'o', mods = mods.alt, action = act.SwitchToWorkspace { name = 'monitoring', spawn = { args = { 'btm' } } } },
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
