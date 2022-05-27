local store = require('kanban.store')
local config = require('kanban.config')
local Main = require('kanban.view.main')
local data = store.load_data(config)

local M = {}
M.load = function()
  local main = Main(data, config)
  main:draw()
end

return M
