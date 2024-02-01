local w = require 'wezterm'
local platform = require 'platform'
local act = w.action

local M = {}

-- TODO: make sure paths exist
local fd = w.home_dir .. '/bin/fd'
local srcPath = w.home_dir .. '/src'

M.toggle = function(window, pane)
  local projects = {}

  local success, stdout, stderr = w.run_child_process {
    fd,
    '-H',
    '-I',
    '-td',
    '--max-depth=1',
    '.',
    srcPath,
    srcPath .. '/work',
    srcPath .. '/www',
  }

  if not success then
    w.log_error('Failed to run fd: ' .. stderr)
    return
  end

  for line in stdout:gmatch '([^\n]*)\n?' do
    local project = line:gsub('\\', '/') -- handles Windows backslash
    local label = project
    local id = project
    table.insert(projects, { label = tostring(label), id = tostring(id) })
  end

  window:perform_action(
    act.InputSelector {
      action = w.action_callback(function(win, _, id, label)
        if not id and not label then
          w.log_info 'Cancelled'
        else
          w.log_info('Selected ' .. label)
          win:perform_action(act.SwitchToWorkspace { name = id, spawn = { cwd = label } }, pane)
        end
      end),
      fuzzy = true,
      title = 'Select project',
      choices = projects,
    },
    pane
  )
end

return M
