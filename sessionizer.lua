local w = require 'wezterm'
local platform = require 'platform'
local act = w.action

local M = {}

--- Converts Windows backslash to forwardslash
---@param path string
local function normalize_path(path) return platform.is_win and path:gsub('\\', '/') or path end

local home = normalize_path(w.home_dir)

--- If name nil or false print err_message
---@param name string|boolean|nil
---@param err_message string
local function err_if_not(name, err_message)
  if not name then
    w.log_error(err_message)
  end
end
--
--- path if file or directory exists nil otherwise
---@param path string
local function file_exists(path)
  if path == nil then
    return nil
  end
  local f = io.open(path, 'r')
  -- io.open won't work to check if directories exist,
  -- but works for symlinks and regular files
  if f ~= nil then
    w.log_info(path .. ' file or symlink found')
    io.close(f)
    return path
  end
  return nil
end

-------------------------------------------------------
-- PATHS
--
local fd = (
  file_exists(home .. '/bin/fd')
  or file_exists(home .. '.cargo/bin/fd')
  or file_exists 'usr/bin/fd'
  -- windows
  or file_exists(home .. '/bin/fd.exe')
  or file_exists(home .. '.cargo/bin/fd.exe')
  or file_exists '/ProgramData/chocolatey/bin/fd.exe'
)
err_if_not(fd, 'fd not found')

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

--- Merge numeric tables
---@param t1 table
---@param t2 table
---@return table
local function merge_tables(t1, t2)
  local result = {}
  for index, value in ipairs(t1) do
    result[index] = value
  end
  for index, value in ipairs(t2) do
    result[#t1 + index] = value
  end
  return result
end

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
  local cmd = merge_tables({ fd, '-HI', '-td', '--max-depth=1', '.' }, search_folders)
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
