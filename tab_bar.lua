local wezterm = require 'wezterm'
local platform = require 'platform'

wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  local alt = (platform.is_mac and '󰘵' or 'Alt')
  local alt_shift = alt .. '󰘶'
  local keybinding_hints = {
    alt .. '  Act Edit eXec Copy Find Debug MODE',
    alt .. '  H←J↓K↑L→ New V-Split sWap Quit Zoom PANE',
    alt .. '  I←O→ TAB',
    alt_shift .. ' I←O→ New/Sel Def. Project' .. '  W.SPACE',
    ' F9-Btm  F10-Top F11-Full' .. '  WIN.',
  }
  for _, x in pairs(keybinding_hints) do
    table.insert(cells, x)
  end

  -- I like my date/time in this style: "Wed Mar 3 08:14"
  -- local date = wezterm.strftime '%v %H:%M'
  local date = wezterm.strftime '%H:%M'
  table.insert(cells, date)

  -- An entry for each battery (typically 0 or 1 battery)
  for _, b in ipairs(wezterm.battery_info()) do
    table.insert(cells, string.format('󰂎%.0f%%', b.state_of_charge * 100))
  end

  -- Color palette for the backgrounds of each cell
  local colors = {
    '#52307c',
    '#52307c',
    '#663a82',
    '#7c5295',
    '#b491c8',
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
  function push(text, is_last)
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
