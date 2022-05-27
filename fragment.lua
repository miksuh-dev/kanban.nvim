local base = {
  version = '1.0',
  board = {},
}

local board = {
  id = nil,
  name = '',
  position = nil,
  description = '',
  modified = '',
  created = '',
  lane = {},
}

local lane = {
  id = nil,
  name = '',
  position = nil,
  card = {},
}

local card = {
  id = nil,
  name = '',
  position = nil,
  description = '',
  modified = '',
  created = '',
  lane = {},
}

local todo = {
  id = nil,
  position = nil,
  name = '',
  description = '',
  modified = '',
  created = '',
  done = false,
}

return {
  base = base,
  board = board,
  lane = lane,
  card = card,
  todo = todo,
}
