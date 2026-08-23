local pickers = require 'whalesalad.pickers'

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

local function leave_insert_mode()
  if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
    vim.cmd.stopinsert()
  end
end

local function open_files()
  leave_insert_mode()
  pickers.files()
end

map({ 'n', 'i' }, '<C-p>', open_files, 'Find project files')
map('n', '<leader>p', pickers.commands, 'Command palette')
map('n', '<leader>b', pickers.buffers, 'Open files')
map('n', '<leader>g', pickers.git_changes, 'Review changed files')
map('n', '<leader>/', pickers.grep, 'Search project text')
map('n', '<leader>?', pickers.keymaps, 'Find key commands')

map('n', '[b', '<cmd>BufferLineCyclePrev<CR>', 'Previous open file')
map('n', ']b', '<cmd>BufferLineCycleNext<CR>', 'Next open file')
map('n', '<M-Left>', '<cmd>BufferLineCyclePrev<CR>', 'Previous open file')
map('n', '<M-Right>', '<cmd>BufferLineCycleNext<CR>', 'Next open file')
map('n', '<leader>w', function()
  _G.whalesalad_close_buffer(vim.api.nvim_get_current_buf())
end, 'Close current file')

map('n', '<C-s>', '<cmd>update<CR>', 'Save file')
map('i', '<C-s>', '<C-o><cmd>update<CR>', 'Save file')

-- Mouse dragging creates a Vim visual selection. These familiar shortcuts
-- move that selection through the desktop clipboard.
map('x', '<C-c>', '"+y', 'Copy selection')
map('x', '<C-x>', '"+d', 'Cut selection')
map('i', '<C-v>', '<C-r>+', 'Paste clipboard')

map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search highlight')

