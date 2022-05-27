local Path = require('plenary.path')
local fragment = require('kanban.fragment')

local M = {}

local function is_readable(file_path)
  local path, _ = file_path:gsub('\\%%', '%%')
  local readable = vim.fn.filereadable(path) == 1

  return readable
end

local function read_data(file_path)
  return vim.fn.json_decode(Path:new(file_path):read())
end

M.load_data = function(config)
  local file_path = config.save_location .. config.save_file

  if not is_readable(file_path) then
    Path:new(file_path):write(vim.fn.json_encode(fragment.base), 'w')
  end

  local ok, data = pcall(read_data, file_path)

  if not ok then
    error('Could not load data file')
  end

  return data
end

M.save_data = function(data, config)
  local file_path = config.save_location .. config.save_file

  Path:new(file_path):write(vim.fn.json_encode(data), 'w')
end

return M
