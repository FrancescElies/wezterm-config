local w = require 'wezterm'

local M = {}

--- path if file or directory exists false otherwise
---@param path string
M.exists = function(path)
  local f = io.open(path, 'r')
  -- io.open won't work for directories, but works for symlinks
  if f ~= nil then
    w.log_info(path .. ' file or symlink found')
    io.close(f)
    return path
  end

  -- This won't work for symlinks, but works for directories
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      w.log_info(path .. ' directory found')
      -- Permission denied, but it exists
      return path
    end
  end

  return false
end

--- Check if a directory exists in this path
M.isdir = function(path)
  -- "/" works on both Unix and Windows
  return exists(path .. '/')
end

return M
