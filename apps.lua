local wezterm = require 'wezterm'

local M = {}

M.start = function(window, pane)
  local apps = {
    { id = 'lazygit', label = 'Lazygit' },
    { id = 'br', label = 'Broot' },
    { id = 'todos', label = 'nvim Todos' },
    { id = 'btm', label = 'Bottom (top)' },
  }

  window:perform_action(
    wezterm.action.InputSelector {
      action = wezterm.action_callback(function(win, _, id, label)
        if not id and not label then
          wezterm.log_info 'Select app cancelled'
        else
          wezterm.log_info('Selected app: ' .. label)
          win:perform_action(
            wezterm.action.SpawnCommandInNewTab {
              args = { 'nu', '-e', id },
            },
            pane
          )
        end
      end),
      fuzzy = true,
      title = 'Select app',
      choices = apps,
    },
    pane
  )
end

return M
