local wezterm = require 'wezterm'
local utils = require 'utils'

local M = {}

local normalize_path = utils.normalize_path
local err_if_not = utils.err_if_not

local home = normalize_path(wezterm.home_dir)

local srcPath = home .. '/src'
err_if_not(srcPath, srcPath .. ' not found')

local folders_to_search = {
  srcPath,
  srcPath .. '/work',
  srcPath .. '/work/ekl',
  srcPath .. '/oss',
}
-------------------------------------------------------

M.start = function(window, pane)
  local projects = {}

  for _, a_folder in ipairs(folders_to_search) do
    for _, project in pairs(wezterm.glob(a_folder .. '/*')) do
      project = normalize_path(project)
      table.insert(projects, { label = project, id = project })
    end
  end

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(win, _, id, label)
        if not id and not label then
          wezterm.log_info 'Cancelled'
        else
          wezterm.log_info('Selected ' .. label)
          win:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = id,
              spawn = {
                cwd = label,
                args = { 'nu', '-e', 'br' }, -- opens broot directly
                -- args = { 'nu' }, just open shell
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
end

return M
