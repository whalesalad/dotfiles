local opt = vim.opt

opt.termguicolors = true
opt.mouse = 'a'
opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.signcolumn = 'yes'
opt.scrolloff = 6

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = 'split'
opt.splitright = true
opt.splitbelow = true
opt.confirm = true
opt.undofile = true

opt.expandtab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.tabstop = 2

opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.laststatus = 3
opt.showmode = false
opt.shortmess:append 'I'
opt.updatetime = 250
opt.timeoutlen = 400

-- Use the desktop clipboard when a provider such as wl-copy is available.
vim.schedule(function()
  opt.clipboard = 'unnamedplus'
end)

-- A quiet, useful status line without another plugin.
opt.statusline = ' %<%f %h%m%r%=%y  %l:%c  %P '

-- These providers are not used by this config. Disabling them keeps
-- :checkhealth focused on things that can affect the editor.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

