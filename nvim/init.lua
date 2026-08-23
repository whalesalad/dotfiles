vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- The directory Nvim starts in is the project. Pickers deliberately keep using
-- this value even if a command or plugin changes the current working directory.
vim.g.whalesalad_project_root = vim.fn.getcwd()

require 'whalesalad.options'
vim.cmd.colorscheme 'whalesalad'
require 'whalesalad.plugins'
require 'whalesalad.pickers'
require 'whalesalad.keymaps'

