local map = vim.keymap.set

map('n', '<Leader>b', function()
  vim.cmd('luafile kanban/load.lua')
end, { silent = true })
