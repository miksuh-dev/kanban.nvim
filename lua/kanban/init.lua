local store = require('kanban.store')
local config = require('kanban.config')
local Main_menu = require('kanban.view.main_menu')
local data = store.load_data(config)

local M = {}
M.load = function()
  local board_width = vim.api.nvim_list_uis()[1].width
  local board_height = vim.api.nvim_list_uis()[1].height

  local dimension = {
    board_width = board_width,
    board_height = board_height,

    width = math.floor(board_width * 0.66),
    height = math.floor(board_height * 0.66),
  }

  local main_menu = Main_menu(nil, data, config, dimension)
  main_menu:draw()
end

return M
