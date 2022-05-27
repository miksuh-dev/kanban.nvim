local M = {}

M.table_clone = function(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

M.generate_board_id = function(data)
  local max = 0

  if data.board then
    for _, board in ipairs(data.board) do
      if board.id > max then
        max = board.id
      end
    end
  end

  return max + 1
end

M.generate_column_id = function(data)
  local max = 0

  if data.board then
    for _, board in ipairs(data.board) do
      if board.column then
        for _, column in ipairs(board.column) do
          if column.id > max then
            max = column.id
          end
        end
      end
    end
  end

  return max + 1
end

M.generate_card_id = function(data)
  local max = 0

  if data.board then
    for _, board in ipairs(data.board) do
      if board.column then
        for _, column in ipairs(board.column) do
          if column.card then
            for _, card in ipairs(column.card) do
              if card.id > max then
                max = card.id
              end
            end
          end
        end
      end
    end
  end

  return max + 1
end

return M
