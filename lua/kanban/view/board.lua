local Column = require('kanban.view.column')

local Board = {}
Board.__index = Board

setmetatable(Board, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Board:_init(parent, data, config)
  local num_columns = vim.fn.len(data.column)
  local active_column_index = 1

  local board_width = vim.api.nvim_list_uis()[1].width
  local board_height = vim.api.nvim_list_uis()[1].height

  local width = math.floor(board_width / num_columns)
  local height = board_height

  local columns = {}
  local remainder = board_width % num_columns
  local x = 0

  for i, column_data in ipairs(data.column) do
    local column_width = width
    if i == num_columns then
      column_width = width + remainder
    end

    local dimension = {
      x = x,
      y = 0,
      width = column_width - 2,
      height = height - 3,
    }

    table.insert(columns, Column(self, column_data, config, dimension))
    x = x + width
  end

  self.columns = columns

  self.parent = parent
  self.data = data
  self.config = config

  self.num_columns = num_columns
  self.active_column_index = active_column_index

  return self
end

function Board:get_column_data(column_id)
  for index, column in ipairs(self.data.column) do
    if column_id == column.id then
      return index, column
    end
  end

  return nil, nil
end

function Board:get_previous_column(column_id)
  local index, _ = self:get_column_data(column_id)
  if index == nil then
    return nil
  end

  local previous_column = self.columns[index - 1]

  if previous_column then
    return previous_column
  end

  return nil
end

function Board:get_next_column(column_id)
  local index, _ = self:get_column_data(column_id)

  if index == nil then
    return nil
  end

  local next_column = self.columns[index + 1]

  if next_column then
    return next_column
  end
end

function Board:update_data(updated_column_data)
  local index, _ = self:get_column_data(updated_column_data.id)
  if index then
    self.data.column[index] = updated_column_data

    return self.parent.update_data(self.parent, self.data)
  end
end

function Board:should_close_column()
  local current_bufnr = vim.api.nvim_get_current_buf()

  for _, column in pairs(self.columns) do
    if column.bufnr == current_bufnr then
      return false
    end
  end

  return true
end

function Board:on_card_change(column_data, active_item)
  for _, column in pairs(self.columns) do
    if column_data.id ~= column.id then
      column.set_active_row(column, active_item.index)
    end
  end
end

function Board:on_column_close(index)
  self:close_all()
end

function Board:close_all()
  for _, column in pairs(self.columns) do
    column:unmount()
  end
end

function Board:draw()
  for i, column in pairs(self.columns) do
    column:draw()
  end

  self.columns[self.active_column_index]:set_active()
end

return Board
