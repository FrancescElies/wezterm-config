local wezterm = require 'wezterm'

local M = {}

local function normalize_path(path)
  local is_win = string.find(wezterm.target_triple, 'windows') ~= nil
  return is_win and path:gsub('\\', '/') or path
end

local home = normalize_path(wezterm.home_dir)

local folders_to_search = {
  home .. '/src',
  home .. '/src/work',
  home .. '/src/work/ekl',
  home .. '/src/oss',
}
-------------------------------------------------------

M.start = function(window, pane)
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
                args = { 'nu', '-e', 'br' }, -- opens broot directly
                -- args = { 'nu' }, -- just open shell
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
