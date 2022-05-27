local Menu = require('nui.menu')
local Board = require('kanban.view.board')
local store = require('kanban.store')
local util = require('kanban.util')

local Main = {}
Main.__index = Main

setmetatable(Main, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Main:_init(data, config)
  local board_width = vim.api.nvim_list_uis()[1].width
  local board_height = vim.api.nvim_list_uis()[1].height

  local width = math.floor(board_width * 0.66)
  local height = math.floor(board_height * 0.66)

  local popup_options = {
    relative = 'editor',
    size = {
      width = width,
      height = height,
    },
    position = {
      col = math.floor(board_width / 2 - width / 2),
      row = math.floor(board_height / 2 - height / 2),
    },
    border = {
      style = 'rounded',
      text = {
        top = config.main.title,
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = 'Normal:Normal',
    },
  }

  local lines = {}
  for _, board in ipairs(data.board) do
    table.insert(lines, Menu.item({ id = tostring(board.id), text = board.name }))
  end

  local menu = Menu(popup_options, {
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

  self.data = data
  self.config = config
  self.menu = menu

  return self
end

function Main:get_board_data(board_id)
  for index, board in ipairs(self.data.board) do
    if board_id == board.id then
      return index, board
    end
  end
  return nil
end

function Main:get_active_board_data()
  if self.active_item then
    local index, card = self:get_board_data(self.active_item.id)
    return index, card
  end

  return nil
end

function Main:update_data(updated_data)
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

function Main:create_board(name, position)
  if name == '' then
    print('Empty board name not allowed!')
    return
  end

  local new_board = {
    id = self:generate_board_id(),
    name = name,
    description = '',
    created_at = os.date('%Y-%m-%d %H:%M:%S'),
    column = {},
  }

  table.insert(self.data.board, position, new_board)

  local success = self:update_data(self.data)
  if not success then
    error('Failed to update data')
    return
  end
end

function Main:load_board(data)
  local board = Board(self, data, self.config)

  return board
end

function Main:set_active_board(board_id)
  local _, board_data = self:get_board_data(board_id)

  if board_data then
    local board = self:load_board(board_data)

    board:draw()
    self.active_board = board
  end
end

function Main:generate_board_id()
  return self:generate_id('board')
end

function Main:generate_id(type)
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

function Main:draw()
  self.menu:mount()

  self.menu:map('n', 'a', function()
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
end

return Main
