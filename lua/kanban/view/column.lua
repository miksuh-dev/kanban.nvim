local Menu = require('nui.menu')
local event = require('nui.utils.autocmd').event
local Card = require('kanban.view.card')
local Input = require('kanban.view.input')
local util = require('kanban.util')

local Column = {}
Column.__index = Column

setmetatable(Column, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Column:_init(parent, data, config, dimension)
  self.parent = parent
  -- self.x = x
  -- self.y = y
  -- self.width = width
  -- self.height = height

  local popup_options = self:create_popup_options(data, dimension, false)
  local lines = self:create_lines(data, config)
  local menu = self:create_menu(popup_options, lines)

  self.menu = menu

  self.parent = parent
  self.data = data
  self.config = config
  self.dimension = dimension

  return self
end

function Column:create_popup_options(data, dimension, selected)
  return {
    relative = 'editor',
    focusable = true,
    enter = false,
    size = {
      width = dimension.width,
      height = dimension.height,
    },
    position = {
      row = dimension.y,
      col = dimension.x,
    },
    border = {
      style = 'rounded',
      text = {
        top = ' ' .. data.name .. ' ',
        top_align = 'center',
      },
    },
    win_options = {
      winhighlight = selected and 'Normal:Normal,FloatBorder:SpecialChar' or 'Normal:Normal,FloatBorder:Normal',
    },
  }
end

function Column:create_lines(data, config)
  local lines = {}
  for _, card_data in ipairs(data.card) do
    local card = Card(self, card_data, config)

    table.insert(lines, Menu.item({ id = tostring(card_data.id), text = card_data.name, card = card }))
  end

  return lines
end

function Column:create_menu(popup_options, lines)
  return Menu(popup_options, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { 'j', '<Down>', '<Tab>' },
      focus_prev = { 'k', '<Up>', '<S-Tab>' },
      close = { '<Esc>', '<C-c>', 'q' },
      submit = { '<Nop>' },
    },
    on_close = function()
      self.parent.on_column_close(self.parent, self.data)
    end,
    on_submit = function(item)
      print('SUBMITTED', vim.inspect(item))
    end,
    on_change = function(item)
      local index, _ = self:get_card_data(tonumber(item.id))
      local active_item = { id = tonumber(item.id), index, text = item.text, card = item.card }
      self.parent.on_card_change(self.parent, self.data, active_item)

      self.active_item = active_item
    end,
  })
end

function Column:set_active()
  local active_card_index = self:get_active_card_data()

  local lines = self:create_lines(self.data, self.config)
  local popup_options = self:create_popup_options(self.data, self.dimension, true)
  local menu = self:create_menu(popup_options, lines)

  if self.menu then
    self.menu:unmount()
  end

  self.menu = menu

  self:draw()
  vim.api.nvim_set_current_buf(self.bufnr)

  if active_card_index then
    vim.api.nvim_win_set_cursor(self.menu.winid, { active_card_index, 0 })
    self.menu._.on_change(self.menu._tree:get_node(active_card_index))
  end

  -- self:set_active()

  -- vim.api.nvim_win_set_cursor(self.menu.winid, { previous_card_index, 0 })
  -- self.menu._.on_change(self.menu._tree:get_node(previous_card_index))
end

function Column:set_active_row(row_index)
  -- local new_index = self.data.card[row_index] and row_index or #self.data.card

  -- vim.api.nvim_win_set_cursor(self.menu.winid, { new_index, 0 })
  -- self.menu._.on_change(self.menu._tree:get_node(new_index))
end

function Column:get_card_data(card_id)
  for index, card in ipairs(self.data.card) do
    if card_id == card.id then
      return index, card
    end
  end

  return nil
end

function Column:get_active_card_data()
  if self.active_item then
    local index, card = self:get_card_data(self.active_item.id)
    return index, card
  end

  return nil
end

function Column:get_previous_card(card_id)
  local index, _ = self:get_card_data(card_id)
  local previous_card = self.data.card[index - 1]

  if previous_card then
    local previous_card_index = index - 1
    return previous_card_index, previous_card
  end
end

function Column:get_next_card(card_id)
  local index, _ = self:get_card_data(card_id)
  local next_card = self.data.card[index + 1]

  if next_card then
    local next_card_index = index + 1
    return next_card_index, next_card
  end
end

function Column:update_data(updated_card_data)
  local index, _ = self:get_card_data(updated_card_data.id)
  if index then
    self.data.card[index] = updated_card_data

    return self.parent.update_data(self.parent, self.data)
  end
end

function Column:generate_card_id()
  return self.parent.parent.generate_id(self.parent.parent, 'card')
end

function Column:create_card(name, position)
  if name == '' then
    print('Empty card name not allowed!')
    return
  end

  local new_card = {
    id = self:generate_card_id(),
    name = name,
    description = '',
    created_at = os.date('%Y-%m-%d %H:%M:%S'),
  }

  table.insert(self.data.card, position, new_card)

  local success = self.parent.update_data(self.parent, self.data)
  if not success then
    error('Failed to update data')
    return
  end

  local lines = self:create_lines(self.data, self.config)
  local popup_options = self:create_popup_options(self.data, self.dimension, true)
  local menu = self:create_menu(popup_options, lines)

  if self.menu then
    self.menu:unmount()
  end

  self.menu = menu

  self:draw()
  self:set_active()

  vim.api.nvim_win_set_cursor(self.menu.winid, { position, 0 })
  self.menu._.on_change(self.menu._tree:get_node(position))
end

function Column:remove_card(index)
  table.remove(self.data.card, index)

  local success = self.parent.update_data(self.parent, self.data)
  if not success then
    error('Failed to update data')
    return
  end

  local lines = self:create_lines(self.data, self.config)
  local popup_options = self:create_popup_options(self.data, self.dimension, true)
  local menu = self:create_menu(popup_options, lines)

  if self.menu then
    self.menu:unmount()
  end

  self.menu = menu

  self:draw()
  self:set_active()

  local new_index = self.data.card[index] and index or index - 1

  vim.api.nvim_win_set_cursor(self.menu.winid, { new_index, 0 })
  self.menu._.on_change(self.menu._tree:get_node(new_index))
end

function Column:draw()
  self.menu:mount()

  self.bufnr = self.menu._tree.bufnr

  self.menu:map('n', self.config.keymap.move_left, function()
    local previous_column = self.parent.get_previous_column(self.parent, self.data.id)
    if previous_column then
      local active_card_index = self:get_active_card_data()

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.dimension, false)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu
      self:draw()
      if self.active_card_index then
        vim.api.nvim_win_set_cursor(self.menu.winid, { active_card_index, 0 })
        self.menu._.on_change(self.menu._tree:get_node(active_card_index))
      end

      previous_column:set_active()
    end
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.move_right, function()
    local next_column = self.parent.get_next_column(self.parent, self.data.id)
    if next_column then
      local active_card_index = self:get_active_card_data()

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.dimension, false)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu
      self:draw()
      if active_card_index then
        vim.api.nvim_win_set_cursor(self.menu.winid, { active_card_index, 0 })
        self.menu._.on_change(self.menu._tree:get_node(active_card_index))
      end

      next_column:set_active()
    end
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.move_item_up, function()
    local active_card_index, active_card = self:get_active_card_data()
    if not active_card then
      return
    end
    local previous_card_index, previous_card = self:get_previous_card(self.active_item.id)

    if previous_card_index then
      local active_card_copy = util.table_clone(active_card)
      local previous_card_copy = util.table_clone(previous_card)

      self.data.card[active_card_index] = previous_card_copy
      self.data.card[previous_card_index] = active_card_copy

      local success = self.parent.update_data(self.parent, self.data)
      if not success then
        error('Failed to update data')
        return
      end

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.dimension, true)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu

      self:draw()
      self:set_active()

      vim.api.nvim_win_set_cursor(self.menu.winid, { previous_card_index, 0 })
      self.menu._.on_change(self.menu._tree:get_node(previous_card_index))
    end
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.move_item_down, function()
    local active_card_index, active_card = self:get_active_card_data()

    local next_card_index, next_card = self:get_next_card(self.active_item.id)

    if next_card_index then
      local active_card_copy = util.table_clone(active_card)
      local next_card_copy = util.table_clone(next_card)

      self.data.card[active_card_index] = next_card_copy
      self.data.card[next_card_index] = active_card_copy

      local success = self.parent.update_data(self.parent, self.data)
      if not success then
        error('Failed to update data')
        return
      end

      local lines = self:create_lines(self.data, self.config)
      local popup_options = self:create_popup_options(self.data, self.dimension, true)
      local menu = self:create_menu(popup_options, lines)

      if self.menu then
        self.menu:unmount()
      end

      self.menu = menu

      self:draw()
      self:set_active()

      vim.api.nvim_win_set_cursor(self.menu.winid, { next_card_index, 0 })
      self.menu._.on_change(self.menu._tree:get_node(next_card_index))
    end
  end, {
    noremap = true,
  }, true)

  -- Add above
  self.menu:map('n', self.config.keymap.create_above, function()
    vim.ui.input('New card title: ', function(name)
      if not name then
        return
      end

      local active_card_index = self:get_active_card_data()
      local new_card_position = active_card_index and active_card_index or 0

      self:create_card(name, new_card_position)
    end)
  end, {
    noremap = true,
  }, true)

  -- Add under
  self.menu:map('n', self.config.keymap.create_below, function()
    vim.ui.input('New card title: ', function(name)
      if not name then
        return
      end

      local active_card_index = self:get_active_card_data()
      local new_card_position = active_card_index and active_card_index or 0

      self:create_card(name, new_card_position + 1)
    end)
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.delete, function()
    vim.ui.input('Delete card (y/n): ', function(answer)
      if answer ~= 'y' then
        return
      end

      local active_card_index = self:get_active_card_data()
      if not active_card_index then
        return
      end

      self:remove_card(active_card_index)
    end)
  end, {
    noremap = true,
  }, true)

  self.menu:map('n', self.config.keymap.select, function()
    P(self.active_item.text)
  end, {
    noremap = true,
  }, true)

  self.menu:on(event.BufLeave, function()
    if self.parent.should_close_column(self.parent, self) then
      self.parent.on_column_close(self.parent, self.data.id)
    end
  end, {
    once = true,
  })
end

function Column:unmount()
  self.menu:unmount()
end

return Column
