return {
  save_location = vim.fn.stdpath('data') .. '/',
  save_file = 'kanban.json',
  main = {
    title = 'Choose board',
  },
  input = {
    width = 20,
    height = 20,
  },
  keymap = {
    select = '<CR>',
    remove = 'x',
    create_below = 'o',
    create_above = 'O',
    move_up = 'k',
    move_down = 'j',
    move_left = 'h',
    move_right = 'l',
    move_item_up = 'K',
    move_item_down = 'J',
    move_item_left = 'H',
    move_item_right = 'L',
  },
}
