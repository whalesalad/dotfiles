local function github(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add({
  github 'nvim-lua/plenary.nvim',
  github 'nvim-telescope/telescope.nvim',
  github 'NMAC427/guess-indent.nvim',
  github 'lewis6991/gitsigns.nvim',
  github 'folke/which-key.nvim',
  github 'akinsho/bufferline.nvim',
  {
    src = github 'saghen/blink.cmp',
    -- Blink v2 is intentionally excluded while it is under active development.
    version = vim.version.range '1.*',
  },
}, { confirm = false })

require('guess-indent').setup {}

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  current_line_blame = false,
}

require('which-key').setup {
  delay = 350,
  icons = { mappings = false },
  spec = {
    { '<leader>f', group = 'find' },
    { '<leader>g', group = 'git changes' },
  },
}

local palette = {
  background = '#090a1b',
  elevated = '#12132a',
  selected = '#1a1b35',
  foreground = '#f8f8f8',
  muted = '#9194a1',
  border = '#333333',
  cyan = '#00ffff',
}

local function close_buffer(bufnr)
  if vim.bo[bufnr].modified then
    vim.api.nvim_set_current_buf(bufnr)
    vim.notify('This file has unsaved changes. Save it or use :bdelete! to discard them.', vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_delete(bufnr, {})
end

_G.whalesalad_close_buffer = close_buffer

local bufferline = require 'bufferline'
bufferline.setup {
  options = {
    mode = 'buffers',
    style_preset = bufferline.style_preset.minimal,
    numbers = 'none',
    close_command = close_buffer,
    right_mouse_command = close_buffer,
    indicator = { style = 'underline' },
    separator_style = 'thin',
    show_buffer_close_icons = false,
    show_close_icon = false,
    color_icons = false,
    diagnostics = false,
    always_show_bufferline = true,
  },
  highlights = {
    fill = { bg = palette.background },
    background = { fg = palette.muted, bg = palette.background },
    buffer_visible = { fg = palette.muted, bg = palette.background },
    buffer_selected = { fg = palette.foreground, bg = palette.elevated, bold = true, italic = false },
    indicator_selected = { fg = palette.cyan, bg = palette.elevated },
    separator = { fg = palette.border, bg = palette.background },
    separator_visible = { fg = palette.border, bg = palette.background },
    separator_selected = { fg = palette.cyan, bg = palette.elevated },
    modified = { fg = palette.cyan, bg = palette.background },
    modified_visible = { fg = palette.cyan, bg = palette.background },
    modified_selected = { fg = palette.cyan, bg = palette.elevated },
  },
}

require('blink.cmp').setup {
  keymap = { preset = 'enter' },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    documentation = { auto_show = false },
    menu = { border = 'single' },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = 'lua' },
  signature = { enabled = true },
}

vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Review and apply plugin updates' })

