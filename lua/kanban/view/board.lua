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
  local active_column_index = 1

  local board_width = vim.api.nvim_list_uis()[1].width
  local board_height = vim.api.nvim_list_uis()[1].height

  local dimension = {
    board_width = board_width,
    board_height = board_height,
  }

  self.columns = self:create_renderable_columns(data, config, dimension)

  self.parent = parent
  self.data = data
  self.config = config
  self.dimension = dimension

  self.active_column_index = active_column_index

  return self
end

function Board:create_renderable_columns(data, config, dimension)
  local num_columns = vim.fn.len(data.column)

  local initial_column_width = math.floor(dimension.board_width / num_columns)
  local initial_column_height = dimension.board_height

  local columns = {}
  local remainder = dimension.board_width % num_columns
  local x = 0

  for i, column_data in ipairs(data.column) do
    local column_width = initial_column_width
    if i == num_columns then
      column_width = initial_column_width + remainder
    end

    local column_dimension = {
      x = x,
      y = 0,
      width = column_width - 2,
      height = initial_column_height - 3,
    }

    table.insert(columns, Column(self, column_data, config, column_dimension))
    x = x + initial_column_width
  end

  return columns
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

function Board:create_column(column, position)
  if column.name == '' then
    print('Empty column name not allowed!')
    return
  end

  local column_count = #self.data.column
  local column_index = position > column_count and column_count + 1 or position

  table.insert(self.data.column, column_index, column)

  local success = self.parent.update_data(self.parent, self.data)
  if not success then
    error('Failed to update data')
    return
  end

  if self.columns then
    self:close_all()
  end

  self.columns = self:create_renderable_columns(self.data, self.config, self.dimension)

  self.active_column_index = position

  self:draw()
end

function Board:swap_column(current_column, target_column)
  local column_index, _ = self:get_column_data(current_column.data.id)
  local target_column_index, _ = self:get_column_data(target_column.data.id)

  table.remove(self.data.column, column_index)
  table.insert(self.data.column, target_column_index, current_column.data)

  local success = self.parent.update_data(self.parent, self.data)
  if not success then
    error('Failed to update data')
    return
  end

  if self.columns then
    self:close_all()
  end

  self.columns = self:create_renderable_columns(self.data, self.config, self.dimension)

  local num_columns = #self.data.column
  self.active_column_index = target_column_index > num_columns and num_columns or target_column_index
  self:draw()
end

function Board:remove_column(index)
  table.remove(self.data.column, index)

  local success = self.parent.update_data(self.parent, self.data)
  if not success then
    error('Failed to update data')
    return
  end

  if self.columns then
    self:close_all()
  end

  self.columns = self:create_renderable_columns(self.data, self.config, self.dimension)

  local num_columns = #self.data.column
  self.active_column_index = index > num_columns and num_columns or index
  self:draw()
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

function Board:on_column_close(index)
  self:close_all()
end

function Board:close_all()
  for _, column in pairs(self.columns) do
    column:unmount()
  end

  self.columns = {}
end

function Board:draw()
  for _, column in pairs(self.columns) do
    column:draw()
  end

  self.columns[self.active_column_index]:set_active()
end

return Board
