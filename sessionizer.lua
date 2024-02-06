local w = require 'wezterm'
local platform = require 'platform'
local act = w.action
local path = require 'path'
local exists = path.exists

local M = {}

local home = platform.is_win and w.home_dir:gsub('\\', '/') or w.home_dir -- handles Windows backslash

--- If name nil or false print err_message
---@param name string|boolean
---@param err_message string
local function err_if_not(name, err_message)
  if not name then
    w.log_error(err_message)
  end
end

-- TODO: make sure at least one path exist
local fd = (exists(home .. '/bin/fd') or exists 'usr/bin/fd' or exists(home .. '/bin/fd.exe') or exists '/ProgramData/chocolatey/bin/fd.exe')
err_if_not(fd, 'fd not found')

local git = (exists '/usr/bin/git' or exists '/Program Files/Git/cmd/git.exe')
err_if_not(git, 'git not found')

local srcPath = exists(home .. '/src')
err_if_not(srcPath, srcPath .. ' not found')

M.toggle = function(window, pane)
  local projects = {}

  -- assumes  ~/src/www, ~/src/work to exist
  -- ~/src
  --  ├──kickstart.nvim       # toplevel config stuff
  --  ├──nushell-config
  --  ├──wezterm-config
  --  ├──work                 # work stuff
  --    └──work/project.git   # git bare clones marked with .git at the end
  --  │ └───31 unlisted
  --  └──www                  # 3rd party project
  --     └──103 unlisted
  local success, stdout, stderr = w.run_child_process {
    fd,
    '-HI',
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
    local project = platform.is_win and line:gsub('\\', '/') or line -- handles Windows backslash
    local label = project
    local id = project

    -- handle git bare repositories,
    -- assuming following name convention `myproject.git`
    if string.match(project, '%.git/$') then
      w.log_info('found ' .. tostring(project) .. ' assuming bare repository (name ends with .git)')
      local success, stdout, stderr = w.run_child_process { fd, '-HI', '-td', '--max-depth=1', '.', project .. '/worktrees' }
      if success then
        for wt_line in stdout:gmatch '([^\n]*)\n?' do
          local wt_project = platform.is_win and wt_line:gsub('\\', '/') or wt_line -- handles Windows backslash
          local wt_label = wt_project
          local wt_id = wt_project
          table.insert(projects, { label = tostring(wt_label), id = tostring(wt_id) })
        end
      else
        w.log_error('Failed to run fd: ' .. stderr)
      end
    end

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
