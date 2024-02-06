local w = require 'wezterm'

local M = {}

--- path if file or directory exists nil otherwise
---@param path string|nil
M.file_exists = function(path)
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

return M
