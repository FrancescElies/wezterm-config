-- https://wezfurlong.org/wezterm/config/lua/keyassignment/
-- https://wezfurlong.org/wezterm/config/default-keys.html
-- https://github.com/yutkat/dotfiles/tree/main/.config/wezterm
-- https://github.com/KevinSilvester/wezterm-config
-- https://github.com/mrjones2014/smart-splits.nvim#wezterm
-- https://github.com/wez/wezterm/discussions/2329

-- NOTE: environment variable WEZTERM_CONFIG_DIR should point to this file
local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
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

config.keys = {

  { key = '0', mods = 'ALT', action = wezterm.action.ResetFontSize },
  { key = '=', mods = 'CTRL|ALT', action = wezterm.action.DecreaseFontSize },
  { key = '=', mods = 'ALT', action = wezterm.action.IncreaseFontSize },

  { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },
  -- { key = 'd',   mods = 'ALT',        action = act.DisableDefaultAssignment },  -- don't remember why

  -- fix ctrl-space not reaching the term https://github.com/wez/wezterm/issues/4055#issuecomment-1694542317
  { key = ' ', mods = 'CTRL', action = act.SendKey { key = ' ', mods = 'CTRL' } },

  -- { key = '^',   mods = "NONE", action = act.SendKey { key = '6', mods = mods.shift_ctrl } },

  -- Main bidings
  { key = 'F9', mods = 'NONE', action = wezterm.action.ToggleAlwaysOnBottom },
  { key = 'F10', mods = 'NONE', action = wezterm.action.ToggleAlwaysOnTop },
  { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },

  { key = '-', mods = 'ALT', action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  { key = '\\', mods = 'ALT', action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },
  {
    key = 'n', -- poor man's zellij New split pane (alt-n)
    mods = 'ALT',
    action = wezterm.action_callback(function(window, pane)
      wezterm.log_info { window, pane }
      local tab = window:active_tab(window)
      local num_panes = #tab:panes_with_info()
      if num_panes == 1 then
        pane:split { direction = 'Right' }
      else
        pane:split { direction = 'Bottom' }
      end
    end),
  },
  -- { key = 's', mods = 'ALT', action = act { SplitVertical = { domain = 'CurrentPaneDomain' } } },
  -- { key = 'v', mods = 'ALT', action = act { SplitHorizontal = { domain = 'CurrentPaneDomain' } } },

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
  { key = 'O', mods = 'ALT|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  {
    key = 'P', -- open Project
    mods = 'ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local function normalize_path(path)
        local is_win = string.find(wezterm.target_triple, 'windows') ~= nil
        return is_win and path:gsub('\\', '/') or path
      end

      local home = normalize_path(wezterm.home_dir)

      local folders_to_search = {
        home .. '/src',
        home .. '/src/work',
        home .. '/src/work/ekl-worktrees',
        home .. '/src/oss',
      }
      -------------------------------------------------------

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
                    -- args = { 'nu', '-e', 'br' }, -- opens broot directly
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
    end),
  },

  { key = 'H', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'L', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'J', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = 'K', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(1) },

  -- https://wezfurlong.org/wezterm/config/lua/keyassignment/ScrollToPrompt.html
  -- This action operates on Semantic Zones defined by applications that use OSC 133 Semantic Prompt Escapes and requires configuring your shell to emit those sequences.
  -- OSC 133 escapes allow marking regions of output as Output (from the commands that you run), Input (that you type) and Prompt ("chrome" from your shell).
  { key = 'UpArrow', mods = 'ALT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'ALT', action = act.ScrollToPrompt(1) },

  { key = 'Enter', mods = 'ALT', action = act.DisableDefaultAssignment }, -- broot uses alt-enter

  -- adjust panes
  { key = 'h', mods = 'ALT|CTRL', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'l', mods = 'ALT|CTRL', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'j', mods = 'ALT|CTRL', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'k', mods = 'ALT|CTRL', action = act.AdjustPaneSize { 'Up', 3 } },

  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },

  { key = 't', mods = 'ALT', action = wezterm.action_callback(function(_, pane) pane:move_to_new_tab() end) },

  {
    key = 'e',
    mods = 'ALT',
    action = wezterm.action_callback(function(window, pane)
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
    end),
  },

  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'ClipboardAndPrimarySelection' },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },
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

wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  local alt = (platform.is_mac and '󰘵' or 'Alt')
  local alt_shift = alt .. ' 󰘶'
  local keybinding_hints = {
    ' : ' .. alt .. ' + [⬆️⬇️]osc133 [A]ct [E]dit e[X]ec [C]opy [F]ind De🐛',
    '󰯋 : ' .. alt .. ' + [HJKL] [-\\N]ew  [Q]uit s[W]ap to[T]ab pane[Z]oom [=]Font🔎',
    '󰋃 : ' .. alt_shift .. ' + [HJKL] [O]pen [P]roject✨',
    '󰡱: 9󰘡  10󰘣  11󰊓',
  }
  for _, x in pairs(keybinding_hints) do
    table.insert(cells, x)
  end

  -- I like my date/time in this style: "Wed Mar 3 08:14"
  -- local date = wezterm.strftime '%v %H:%M'
  -- local date = wezterm.strftime '%H:%M'
  -- table.insert(cells, date)

  -- local charge_syms = { '󰁺', '󰁻', '󰁼', '󰁽', '󰁾', '󰁿', '󰂀', '󰂁', '󰂂', '󰁹', '󰁹' }
  -- -- An entry for each battery (typically 0 or 1 battery)
  -- for _, b in ipairs(wezterm.battery_info()) do
  --   local charge = b.state_of_charge * 100
  --   table.insert(cells, string.format(charge_syms[math.floor(charge / 10 + 1.5)] .. '%.0f%%', charge))
  -- end

  -- Color palette for the backgrounds of each cell
  local colors = {
    -- pastel gradient -n 6 silver indigo | pastel darken 0.1 | pastel format hex
    -- violets
    '#2e004f',
    '#4b2469',
    '#64437b',
    '#7d5d90',
    '#937f9e',
    -- blues
    '#3c5295',
    '#3491c8',
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

  window:set_left_status(window:active_workspace():match '[%a%s-._]+$')
  window:set_right_status(wezterm.format(elements))
end)

return config
