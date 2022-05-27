local InputNui = require('nui.input')
local event = require('nui.utils.autocmd').event

local Input = {}
Input.__index = Input

setmetatable(Input, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Input:_init(parent, details, config, events)
  local input = InputNui({
    relative = 'editor',
    size = {
      width = config.input.width,
      height = config.input.height,
    },
    position = {
      row = 10,
      col = 10,
    },
    border = {
      style = 'single',
      text = {
        top = details.title,
        top_align = 'center',
      },
    },
    win_options = {
      winblend = 10,
      winhighlight = 'Normal:Normal',
    },
  }, {
    prompt = '> ',
    default_value = '',
    on_close = events.on_close,
    on_submit = events.on_submit,
  })

  -- mount/open the component
  input:mount()

  -- unmount component when cursor leaves buffer
  input:on(event.BufLeave, function()
    input:unmount()
  end)

  self.parent = parent
  self.input = input

  return self
end

return Input
