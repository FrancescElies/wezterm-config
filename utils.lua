local w = require 'wezterm'
local platform = require 'platform'

local M = {}
--- path if file or directory exists nil otherwise
---@param path string
M.file_exists = function(path)
  if path == nil then
    w.log_warn(path .. ' NOT found')
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
  w.log_warn(path .. ' NOT found')
  return nil
end

--- Converts Windows backslash to forwardslash
---@param path string
M.normalize_path = function(path) return platform.is_win and path:gsub('\\', '/') or path end

--- If name nil or false print err_message
---@param name string|boolean|nil
---@param err_message string
M.err_if_not = function(name, err_message)
  if not name then
    w.log_error(err_message)
  end
end

--- Merge numeric tables
---@param t1 table
---@param t2 table
---@return table
M.merge_tagles = function(t1, t2)
  local result = {}
  for index, value in ipairs(t1) do
    result[index] = value
  end
  for index, value in ipairs(t2) do
    result[#t1 + index] = value
  end
  return result
end

return M
