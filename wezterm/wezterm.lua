-- https://wezfurlong.org/wezterm/config/lua/keyassignment/
-- https://wezfurlong.org/wezterm/config/default-keys.html
-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm
-- https://github.com/wez/wezterm/discussions/2329

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local wezterm = require 'wezterm'
local act = wezterm.action
-- local mux = wezterm.mux
local io = require 'io'
local os = require 'os'

local platform = {
  is_win = string.find(wezterm.target_triple, 'windows') ~= nil,
  is_linux = string.find(wezterm.target_triple, 'linux') ~= nil,
  is_mac = string.find(wezterm.target_triple, 'apple') ~= nil,
}

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

config.font_size = 11

config.disable_default_key_bindings = true
-- config.hide_tab_bar_if_only_one_tab = true
-- https://wezfurlong.org/wezterm/config/lua/config/debug_key_events.html
config.debug_key_events = false

config.hide_mouse_cursor_when_typing = true
config.pane_focus_follows_mouse = false

config.switch_to_last_active_tab_when_closing_tab = false
config.adjust_window_size_when_changing_font_size = false

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

local function normalize_path(path)
  local is_win = string.find(wezterm.target_triple, 'windows') ~= nil
  return is_win and path:gsub('\\', '/') or path
end

local home = normalize_path(wezterm.home_dir)
local folders_to_search = {}
if platform.is_win then
  folders_to_search = {
    home .. '/src',
    home .. '/src/work',
    home .. '/src/work/ekl-worktrees',
    home .. '/src/work/customerprj/',
    home .. '/src/oss',
  }
else
  folders_to_search = {
    home .. '/src',
    home .. '/src/oss',
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
  brightness = 1, -- dims or increases the perceived amount of light
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
  {
    event = { Down = { streak = 3, button = 'Left' } },
    action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
    mods = 'NONE',
  },
}

local mods = 'CTRL|SHIFT'

local edit_pane_in_nvim = wezterm.action_callback(function(window, pane)
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

local new_pane = wezterm.action_callback(function(window, pane)
  wezterm.log_info { window, pane }
  local tab = window:active_tab(window)
  local num_panes = #tab:panes_with_info()
  if num_panes == 1 then
    pane:split { direction = 'Right' }
  else
    pane:split { direction = 'Bottom' }
  end
end)

local open_project = wezterm.action_callback(function(window, pane)
  local projects = {}

  for _, folder in ipairs(folders_to_search) do
    wezterm.log_info(folder)
    for _, project in pairs(wezterm.glob(folder .. '/*')) do
      project = normalize_path(project)
      table.insert(projects, { label = project, id = project })
    end
  end

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(win, _, id, label)
        if not id and not label then
          wezterm.log_info 'Select Project cancelled'
        else
          wezterm.log_info('Selected project: ' .. label)
          win:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = id,
              spawn = {
                cwd = label,
                -- args = { 'nu', '-e', 'nvim' }, -- open nvim
                args = { 'nu' }, -- just open shell
              },
            },
            pane
          )
        end
      end),
      fuzzy = true,
      title = 'Select project',
      choices = projects,
    },
    pane
  )
end)

local break_to_new_tab = wezterm.action_callback(function(_, pane) pane:move_to_new_tab() end)

config.keys = {

  { key = '0', mods = 'ALT', action = wezterm.action.ResetFontSize },
  { key = '-', mods = 'ALT', action = wezterm.action.DecreaseFontSize },
  { key = '=', mods = 'ALT', action = wezterm.action.IncreaseFontSize },

  { key = 'z', mods = mods, action = act.TogglePaneZoomState },
  -- { key = 'd',   mods = mods,        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = 'Enter', mods = 'CTRL', action = act.SendKey { key = 'Enter', mods = 'CTRL' } },
  { key = ' ', mods = 'CTRL', action = act.SendKey { key = ' ', mods = 'CTRL' } },
  { key = ',', mods = 'CTRL', action = act.SendKey { key = ',', mods = 'CTRL' } },
  { key = 'm', mods = 'CTRL', action = act.SendKey { key = 'Enter' } },
  { key = 'i', mods = 'CTRL', action = act.SendKey { key = 'Tab' } },
  { key = '[', mods = 'CTRL', action = act.SendKey { key = 'Escape' } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },

  -- Main bidings
  { key = 'F9', mods = 'NONE', action = wezterm.action.ToggleAlwaysOnBottom },
  { key = 'F10', mods = 'NONE', action = wezterm.action.ToggleAlwaysOnTop },
  { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },

  -- { key = 's', mods = mods, action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  -- { key = 'v', mods = mods, action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  { key = 'n', mods = mods, action = new_pane }, -- poor man's zellij New split pane

  { key = 'a', mods = mods, action = act.ActivateCommandPalette }, -- [c]ommands
  { key = 'd', mods = mods, action = act.ShowDebugOverlay },
  { key = 's', mods = mods, action = act.Search { CaseInSensitiveString = '' } }, -- [f]ind
  { key = 'r', mods = mods, action = act.RotatePanes 'Clockwise' }, -- [r]otate panes
  { key = 'u', mods = mods, action = act.CharSelect }, -- insert [u]nicode character, e.g. emoji

  -- Workspaces (alt + shift)
  { key = 'o', mods = mods, action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 'p', mods = mods, action = open_project },

  { key = 't', mods = mods, action = act.ActivateTabRelative(1) },
  { key = 'w', mods = mods, action = act.SwitchWorkspaceRelative(1) },

  -- adjust panes
  { key = 'LeftArrow', mods = mods, action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = mods, action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'DownArrow', mods = mods, action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'UpArrow', mods = mods, action = act.AdjustPaneSize { 'Up', 3 } },

  { key = 'h', mods = mods, action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = mods, action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = mods, action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = mods, action = act.ActivatePaneDirection 'Right' },

  { key = 'x', mods = mods, action = act.CloseCurrentPane { confirm = false } },

  { key = 'b', mods = mods, action = break_to_new_tab },

  { key = 'e', mods = mods, action = edit_pane_in_nvim },

  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'ClipboardAndPrimarySelection' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
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

-- https://wezterm.org/config/lua/window/set_right_status.html
wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  -- Figure out the cwd and host of the current pane.
  -- This will pick up the hostname for the remote host if your
  -- shell is using OSC 7 on the remote host.
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local cwd = ''
    local hostname = ''

    if type(cwd_uri) == 'userdata' then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      ---@diagnostic disable-next-line: undefined-field
      cwd = cwd_uri.file_path
      ---@diagnostic disable-next-line: undefined-field
      hostname = cwd_uri.host or wezterm.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find '/'
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub('%%(%x%x)', function(hex) return string.char(tonumber(hex, 16)) end)
      end
    end

    -- Remove the domain name portion of the hostname
    local dot = hostname:find '[.]'
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == '' then
      hostname = wezterm.hostname()
    end

    table.insert(cells, cwd)
    table.insert(cells, hostname)
  end

  -- I like my date/time in this style: "Wed Mar 3 08:14"
  local date = wezterm.strftime '%a %b %-d %H:%M'
  table.insert(cells, date)

  -- An entry for each battery (typically 0 or 1 battery)
  for _, b in ipairs(wezterm.battery_info()) do
    table.insert(cells, string.format('%.0f%%', b.state_of_charge * 100))
  end

  -- The powerline < symbol
  ---@diagnostic disable-next-line: undefined-global
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  -- Color palette for the backgrounds of each cell
  local colors = {
    '#3c1361',
    '#52307c',
    '#663a82',
    '#7c5295',
    '#b491c8',
  }

  -- Foreground color for the text across the fade
  local text_fg = '#c0c0c0'

  -- The elements to be formatted
  local elements = {}
  -- How many cells have been formatted
  local num_cells = 0

  -- Translate a cell into elements
  local function push(text, is_last)
    local cell_no = num_cells + 1
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = ' ' .. text .. ' ' })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)

return config
