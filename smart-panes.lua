-- WARN: this doesn't work reliably under windows,
-- thus not using it, but don't want to delete this yet
--
-- NOTE:this would be the nvim config
-- local function go_left()
--   require('smart-splits').move_cursor_left()
-- end
-- local function go_right()
--   require('smart-splits').move_cursor_right()
-- end
-- local function go_down()
--   require('smart-splits').move_cursor_down()
-- end
-- local function go_up()
--   require('smart-splits').move_cursor_up()
-- end
-- return {
--   'mrjones2014/smart-splits.nvim',
--   config = function()
--     require('smart-splits').setup {
--       -- at_edge = 'stop',
--       -- log_level = 'debug',
--     }
--   end,
--   keys = {
--     { '<A-h>', go_left, desc = 'go left pane' },
--     { '<A-l>', go_right, desc = 'go right pane' },
--     { '<A-j>', go_down, desc = 'go down pane' },
--     { '<A-k>', go_up, desc = 'go up pane' },
--     { '<A-x>', '<C-w>q', desc = 'close pane' },
--   },
-- }

local function is_nvim(process) return string.find((process or {}).name or 'no-process', 'nvim') end

local function children_has_nvim(proc)
  if proc == nil then
    return false
  end

  wezterm.log_info('check children for', proc.name)
  -- quick and dirty check without recursion, 2 level children check for nvim
  for child_pid, child in pairs(proc.children) do
    wezterm.log_info('child of ' .. proc.name .. ': name=' .. child.name .. ' pid=' .. child_pid)
    if is_nvim(child) then
      return true
    end
    -- NOTE: this covers the case where nvim is started from broot
    for grandchild_pid, grandchild in pairs(child.children) do
      wezterm.log_info('child of ' .. child.name .. ': name=' .. grandchild.name .. ' pid=' .. grandchild_pid)
      if is_nvim(grandchild) then
        return true
      end
    end
  end
end

local function parent_has_nvim(proc)
  if proc == nil then
    return false
  end

  local parent_proc = wezterm.procinfo.get_info_for_pid(proc.ppid)
  if parent_proc == nil then
    wezterm.log_info('parent of', proc.name, 'is nil')
    return false
  end

  wezterm.log_info('parent of', proc.name, 'is', parent_proc.name)
  if is_nvim(parent_proc) then
    return true
  else
    return parent_has_nvim(parent_proc)
  end
end

local function window_has_nvim(window)
  wezterm.log_info 'window_has_nvim?'

  -- check current process
  local p = mux.get_window(window:window_id()):active_pane():get_foreground_process_info()

  if is_nvim(p) then
    wezterm.log_info('get_foreground_process_info' .. p.name)
    return true
  end

  return parent_has_nvim(p) or children_has_nvim(p)
end

local function wez_nvim_action(window, pane, action_wez, forward_key_nvim)
  if window_has_nvim(window) then
    wezterm.log_info('is nvim, forwarding', forward_key_nvim)
    window:perform_action(forward_key_nvim, pane)
  else
    wezterm.log_info('not nvim, executing', action_wez)
    window:perform_action(action_wez, pane)
  end
end

-- keep in sync with nvim wezterm.lua
wezterm.on('move-left', function(window, pane) wez_nvim_action(window, pane, act.ActivatePaneDirection 'Left', act.SendKey { key = 'h', mods = 'ALT' }) end)
wezterm.on('move-right', function(window, pane) wez_nvim_action(window, pane, act.ActivatePaneDirection 'Right', act.SendKey { key = 'l', mods = 'ALT' }) end)
wezterm.on('move-up', function(window, pane) wez_nvim_action(window, pane, act.ActivatePaneDirection 'Up', act.SendKey { key = 'k', mods = 'ALT' }) end)
wezterm.on('move-down', function(window, pane) wez_nvim_action(window, pane, act.ActivatePaneDirection 'Down', act.SendKey { key = 'j', mods = 'ALT' }) end)

-- you can add other actions, this unifies the way in which panes and windows are closed
-- (you'll need to bind <A-x> -> <C-w>q)
wezterm.on(
  'close-pane',
  function(window, pane) wez_nvim_action(window, pane, act.CloseCurrentPane { confirm = false }, act.SendKey { key = 'x', mods = 'ALT' }) end
)
-- move between neovim and wezterm panes
-- { key = 'h', mods = 'ALT', action = act { EmitEvent = 'move-left' } },
-- { key = 'l', mods = 'ALT', action = act { EmitEvent = 'move-right' } },
-- { key = 'j', mods = 'ALT', action = act { EmitEvent = 'move-down' } },
-- { key = 'k', mods = 'ALT', action = act { EmitEvent = 'move-up' } },
-- { key = 'x', mods = 'ALT', action = act { EmitEvent = 'close-pane' } }, -- close pane
