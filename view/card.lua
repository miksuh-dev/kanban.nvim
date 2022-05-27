local Card = {}
Card.__index = Card

setmetatable(Card, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Card:_init(parent, data, config)
  self.parent = parent
  self.data = data
  self.config = config

  return self
end

function Card:update_data(updated_card_data)
  return self.parent.update_data(self.parent, updated_card_data)
end

return Card
