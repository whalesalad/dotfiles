local builtin = require 'telescope.builtin'
local actions = require 'telescope.actions'

local M = {}

local function root()
  return vim.g.whalesalad_project_root
end

require('telescope').setup {
  defaults = {
    prompt_prefix = '› ',
    selection_caret = '› ',
    path_display = { 'truncate' },
    sorting_strategy = 'ascending',
    layout_config = { prompt_position = 'top' },
    mappings = {
      i = {
        ['<Esc>'] = actions.close,
        ['<Up>'] = actions.move_selection_previous,
        ['<Down>'] = actions.move_selection_next,
      },
    },
  },
}

function M.files()
  builtin.find_files {
    cwd = root(),
    prompt_title = 'Project files',
    find_command = { 'rg', '--files', '--hidden', '--glob', '!.git' },
    previewer = false,
    layout_strategy = 'center',
    layout_config = {
      width = 0.78,
      height = 0.62,
      prompt_position = 'top',
    },
  }
end

function M.commands()
  builtin.commands {
    prompt_title = 'Commands',
    layout_strategy = 'center',
    layout_config = {
      width = 0.78,
      height = 0.62,
      prompt_position = 'top',
    },
  }
end

function M.buffers()
  builtin.buffers {
    prompt_title = 'Open files',
    sort_mru = true,
    ignore_current_buffer = true,
    previewer = false,
    layout_strategy = 'center',
    layout_config = {
      width = 0.78,
      height = 0.62,
      prompt_position = 'top',
    },
  }
end

function M.grep()
  builtin.live_grep {
    cwd = root(),
    prompt_title = 'Search project text',
  }
end

function M.git_changes()
  local result = vim.system({ 'git', '-C', root(), 'rev-parse', '--is-inside-work-tree' }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify('The project directory is not a Git repository.', vim.log.levels.INFO)
    return
  end

  builtin.git_status {
    cwd = root(),
    prompt_title = 'Changed files',
    layout_strategy = 'horizontal',
    layout_config = {
      width = 0.98,
      height = 0.95,
      preview_width = 0.62,
      prompt_position = 'top',
    },
    attach_mappings = function(_, map)
      -- Telescope normally stages files with Tab in this picker. This setup is
      -- intentionally review-only, so Tab merely marks a result.
      map({ 'i', 'n' }, '<Tab>', actions.toggle_selection)
      return true
    end,
  }
end

function M.keymaps()
  builtin.keymaps {
    prompt_title = 'Key commands',
    layout_strategy = 'center',
    layout_config = {
      width = 0.82,
      height = 0.72,
      prompt_position = 'top',
    },
  }
end

return M
