local Menu = require('nui.menu')
local Board = require('kanban.view.board')
local store = require('kanban.store')
local util = require('kanban.util')

local Main_menu = {}
Main_menu.__index = Main_menu

setmetatable(Main_menu, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Main_menu:_init(parent, data, config, dimension)
  local popup_options = self:create_popup_options(data, config, dimension)
  local lines = self:create_lines(data, config)
  local menu = self:create_menu(popup_options, lines)

  self.data = data
  self.config = config
  self.dimension = dimension
  self.menu = menu

  return self
end

function Main_menu:create_lines(data, config)
  local lines = {}
  for _, board in ipairs(data.board) do
    table.insert(lines, Menu.item({ id = tostring(board.id), text = board.name }))
  end

  return lines
end

function Main_menu:create_popup_options(data, config, dimension)
  return {
    relative = 'editor',
    size = {
      width = dimension.width,
      height = dimension.height,
    },
    position = {
      col = math.floor(dimension.board_width / 2 - dimension.width / 2),
      row = math.floor(dimension.board_height / 2 - dimension.height / 2),
    },
    border = {
      style = 'rounded',
      text = {
        top = ' ' .. config.main.title .. ' ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  }
end

function Main_menu:create_menu(popup_options, lines)
  return Menu(popup_options, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { 'j', '<Down>', '<Tab>' },
      focus_prev = { 'k', '<Up>', '<S-Tab>' },
      close = { '<Esc>', '<C-c>', 'q' },
      submit = { '<Enter>' },
    },
    on_close = function() end,
    on_submit = function(board)
      self:set_active_board(tonumber(board.id))
    end,
    on_change = function(item)
      local index, _ = self:get_board_data(tonumber(item.id))
      local active_item = { id = tonumber(item.id), index, text = item.text }

      self.active_item = active_item
    end,
  })
end

function Main_menu:get_board_data(board_id)
  for index, board in ipairs(self.data.board) do
    if board_id == board.id then
      return index, board
    end
  end
  return nil
end

function Main_menu:get_active_board_data()
  if self.active_item then
    local index, card = self:get_board_data(self.active_item.id)
    return index, card
  end

  return nil
end

function Main_menu:get_previous_board(board_id)
  local index, _ = self:get_board_data(board_id)
  local previous_board = self.data.board[index - 1]

  if previous_board then
    local previous_board_index = index - 1
    return previous_board_index, previous_board
  end
end

function Main_menu:get_next_board(board_id)
  local index, _ = self:get_board_data(board_id)
  local next_board = self.data.board[index + 1]

  if next_board then
    local next_board_index = index + 1
    return next_board_index, next_board
  end
end

function Main_menu:update_data(updated_data)
  -- In main
  if updated_data.board then
    store.save_data(self.data, self.config)

    return self.data
  end

  -- Inside board
  local index, _ = self:get_board_data(updated_data.id)
  if index then
    self.data.board[index] = updated_data

    store.save_data(self.data, self.config)

    -- TODO: Handle save error
    return self.data
  end
end

function Main_menu:create_board(name, position)
  if name == '' then
    print('Empty board name not allowed!')
    return
  end

  local new_board = {
    id = self:generate_id('board'),
    name = name,
    description = '',
    created_at = os.date('%Y-%m-%d %H:%M:%S'),
    column = {
      {
        id = self:generate_id('column'),
        name = 'Column 1',
        position = nil,
        description = '',
        modified = '',
        created_at = os.date('%Y-%m-%d %H:%M:%S'),
        card = {},
      },
    },
  }

  table.insert(self.data.board, position, new_board)

  local success = self:update_data(self.data)
  if not success then
    error('Failed to update data')
    return
  end

  local lines = self:create_lines(self.data, self.config)
  local popup_options = self:create_popup_options(self.data, self.config, self.dimension)
  local menu = self:create_menu(popup_options, lines)

  if self.menu then
    self.menu:unmount()
  end

  self.menu = menu

  self:draw()

  vim.api.nvim_win_set_cursor(self.menu.winid, { position, 0 })
  self.menu._.on_change(self.menu._tree:get_node(position))
end

function Main_menu:remove_board(index)
  table.remove(self.data.board, index)

  local success = self:update_data(self.data)
  if not success then
    error('Failed to update data')
    return
  end

  local lines = self:create_lines(self.data, self.config)
  local popup_options = self:create_popup_options(self.data, self.config, self.dimension)
  local menu = self:create_menu(popup_options, lines)

  if self.menu then
    self.menu:unmount()
  end

  self.menu = menu

  self:draw()

  local new_index = self.data.board[index] and index or index - 1

  vim.api.nvim_win_set_cursor(self.menu.winid, { new_index, 0 })
  self.menu._.on_change(self.menu._tree:get_node(new_index))
end

function Main_menu:load_board(data)
  local board = Board(self, data, self.config)

  return board
end

function Main_menu:set_active_board(board_id)
  local _, board_data = self:get_board_data(board_id)

  if board_data then
    local board = self:load_board(board_data)

    board:draw()
    self.active_board = board
  end
end

function Main_menu:generate_id(type)
  if type == 'board' then
    return util.generate_board_id(self.data)
  end

  if type == 'column' then
    return util.generate_column_id(self.data)
  end

  if type == 'card' then
    return util.generate_card_id(self.data)
  end
end

function Main_menu:draw()
  self.menu:mount()

  self.menu:map('n', self.config.keymap.move_item_up, function()
    local active_board_index, active_board = self:get_active_board_data()
    if not active_board then
      return
    end
    local previous_board_index, previous_board = self:get_previous_board(self.active_item.id)

    if previous_board_index then
      local active_board_copy = util.table_clone(active_board)
      local previous_board_copy = util.table_clone(previous_board)

      self.data.board[active_board_index] = previous_board_copy
      self.data.board[previous_board_index] = active_board_copy

      local success = self:update_data(self.data)
      if not success then
        error('Failed to update data')
        return
      end

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.config, self.dimension)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu

      self:draw()

      vim.api.nvim_win_set_cursor(self.menu.winid, { previous_board_index, 0 })
      self.menu._.on_change(self.menu._tree:get_node(previous_board_index))
    end
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.move_item_down, function()
    local active_board_index, active_board = self:get_active_board_data()

    local next_board_index, next_board = self:get_next_board(self.active_item.id)

    if next_board_index then
      local active_board_copy = util.table_clone(active_board)
      local next_board_copy = util.table_clone(next_board)

      self.data.board[active_board_index] = next_board_copy
      self.data.board[next_board_index] = active_board_copy

      local success = self:update_data(self.data)
      if not success then
        error('Failed to update data')
        return
      end

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.config, self.dimension)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu

      self:draw()

      vim.api.nvim_win_set_cursor(self.menu.winid, { next_board_index, 0 })
      self.menu._.on_change(self.menu._tree:get_node(next_board_index))
    end
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.create_above, function()
    vim.ui.input('New board title: ', function(name)
      if not name then
        return
      end

      local active_board_index = self:get_active_board_data()
      local new_board_position = active_board_index and active_board_index or 0

      self:create_board(name, new_board_position)
    end)
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.create_below, function()
    vim.ui.input('New board title: ', function(name)
      if not name then
        return
      end

      local active_board_index = self:get_active_board_data()
      local new_board_position = active_board_index and active_board_index or 0

      self:create_board(name, new_board_position + 1)
    end)
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.remove, function()
    vim.ui.input('Remove board (y/n): ', function(answer)
      if answer ~= 'y' then
        return
      end

      local active_board_index = self:get_active_board_data()
      if not active_board_index then
        return
      end

      self:remove_board(active_board_index)
    end)
  end, {
    noremap = true,
  }, true)
end

return Main_menu
