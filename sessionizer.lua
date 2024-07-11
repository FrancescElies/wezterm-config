local w = require 'wezterm'
local platform = require 'platform'
local utils = require 'utils'
local act = w.action

local M = {}

local file_exists = utils.file_exists
local normalize_path = utils.normalize_path
local err_if_not = utils.err_if_not

local home = normalize_path(w.home_dir)

-------------------------------------------------------
-- PATHS
--

--- Find exececutable in typical locations
---@param bin_name string
---@return string
local function find_executable(bin_name)
  local bin = (
    file_exists(home .. '/bin/' .. bin_name)
    or file_exists(home .. '/.cargo/bin/' .. bin_name)
    or file_exists('usr/bin/' .. bin_name)
    -- windows
    or file_exists(home .. '/bin/' .. bin_name .. '.exe')
    or file_exists(home .. '/.cargo/bin/' .. bin_name .. '.exe')
    or file_exists '/ProgramData/chocolatey/bin/' .. bin_name .. '.exe'
  )
  err_if_not(bin, bin_name .. ' not found')

  return bin
end

local fd = find_executable 'fd'

local git = (file_exists '/usr/bin/git' or file_exists '/Program Files/Git/cmd/git.exe')
err_if_not(git, 'git not found')

local srcPath = home .. '/src'
err_if_not(srcPath, srcPath .. ' not found')

local search_folders = {
  srcPath,
  srcPath .. '/work',
  srcPath .. '/oss',
}
-------------------------------------------------------

M.start = function(window, pane)
  local projects = {}

  -- assumes  ~/src/www, ~/src/work to exist
  -- ~/src
  --  ├──nushell-config       # toplevel config stuff
  --  ├──wezterm-config
  --  ├──work                    # work stuff
  --    ├──work/project.git      # git bare clones marked with .git at the end
  --    ├──work/project-bugfix   # worktree of project.git
  --    ├──work/project-feature  # worktree of project.git
  --  │ └───31 unlisted
  --  └──other                # 3rd party project
  --     └──103 unlisted
  local cmd = utils.merge_tables({ fd, '-HI', '-td', '--max-depth=1', '.' }, search_folders)
  w.log_info 'cmd: '
  w.log_info(cmd)

  for _, value in ipairs(cmd) do
    w.log_info(value)
  end
  local success, stdout, stderr = w.run_child_process(cmd)

  if not success then
    w.log_error('Failed to run fd: ' .. stderr)
    return
  end

  for line in stdout:gmatch '([^\n]*)\n?' do
    local project = normalize_path(line)
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
          win:perform_action(act.SwitchToWorkspace { name = id, spawn = { cwd = label, args = { 'broot' } } }, pane)
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
