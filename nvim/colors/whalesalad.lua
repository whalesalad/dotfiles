vim.cmd.highlight 'clear'
vim.o.background = 'dark'
vim.g.colors_name = 'whalesalad'

local p = {
  bg = '#090a1b',
  surface = '#0d0e1f',
  elevated = '#12132a',
  hover = '#1a1b35',
  active_line = '#28293a',
  fg = '#f8f8f8',
  muted = '#9194a1',
  dim = '#666666',
  border = '#333333',
  border_bright = '#444444',
  selection = '#04447f',
  cyan = '#00ffff',
  blue = '#588aff',
  blue_bright = '#0a9cff',
  blue_soft = '#6fd3ff',
  cyan_soft = '#45c1ea',
  green = '#8fff58',
  green_soft = '#99cf50',
  mint = '#00ffbc',
  red = '#ff3854',
  error = '#ff5555',
  magenta = '#d972de',
  magenta_bright = '#fd5ff1',
  gold = '#f0b850',
  yellow = '#e9c062',
  orange = '#cf7d34',
  link = '#578bb3',
  string_bg = '#102622',
  comment_bg = '#20212e',
  error_bg = '#562d56',
  warning_bg = '#4a3a1a',
}

local function hi(group, options)
  vim.api.nvim_set_hl(0, group, options)
end

-- Editor chrome
hi('Normal', { fg = p.fg, bg = p.bg })
hi('NormalNC', { fg = p.fg, bg = p.bg })
hi('NormalFloat', { fg = p.fg, bg = p.elevated })
hi('FloatBorder', { fg = p.border_bright, bg = p.elevated })
hi('FloatTitle', { fg = p.blue_soft, bg = p.elevated, bold = true })
hi('Cursor', { fg = p.bg, bg = p.cyan })
hi('CursorLine', { bg = p.active_line })
hi('CursorColumn', { bg = p.active_line })
hi('ColorColumn', { bg = p.surface })
hi('LineNr', { fg = p.dim, bg = p.bg })
hi('CursorLineNr', { fg = p.cyan, bg = p.active_line, bold = true })
hi('SignColumn', { fg = p.muted, bg = p.bg })
hi('Visual', { bg = p.selection })
hi('Search', { fg = p.bg, bg = p.yellow })
hi('IncSearch', { fg = p.bg, bg = p.cyan })
hi('CurSearch', { fg = p.bg, bg = p.cyan })
hi('MatchParen', { fg = p.cyan, bg = p.hover, bold = true })
hi('NonText', { fg = p.border })
hi('Whitespace', { fg = p.border })
hi('EndOfBuffer', { fg = p.bg })
hi('Directory', { fg = p.blue_soft })
hi('Title', { fg = p.blue_soft, bold = true })
hi('Question', { fg = p.mint })
hi('MoreMsg', { fg = p.mint })
hi('WarningMsg', { fg = p.fg, bg = p.warning_bg })
hi('ErrorMsg', { fg = p.error, bg = p.error_bg })

hi('StatusLine', { fg = p.fg, bg = p.surface })
hi('StatusLineNC', { fg = p.muted, bg = p.bg })
hi('WinSeparator', { fg = p.border, bg = p.bg })
hi('TabLine', { fg = p.muted, bg = p.bg })
hi('TabLineFill', { bg = p.bg })
hi('TabLineSel', { fg = p.fg, bg = p.elevated, bold = true })

hi('Pmenu', { fg = p.fg, bg = p.elevated })
hi('PmenuSel', { fg = p.fg, bg = p.selection })
hi('PmenuSbar', { bg = p.surface })
hi('PmenuThumb', { bg = p.border_bright })
hi('WildMenu', { fg = p.fg, bg = p.selection })

-- Syntax, ported from zed/whalesalad.json. Zed's alpha backgrounds are
-- flattened here because terminal cells do not support per-highlight alpha.
hi('Comment', { fg = p.muted, bg = p.comment_bg, italic = true })
hi('String', { fg = p.green, bg = p.string_bg })
hi('Character', { link = 'String' })
hi('Number', { fg = p.blue_bright })
hi('Float', { link = 'Number' })
hi('Boolean', { fg = p.blue_bright })
hi('Constant', { fg = p.blue_bright })
hi('Identifier', { fg = p.blue })
hi('Function', { fg = p.gold })
hi('Statement', { fg = p.red })
hi('Conditional', { fg = p.red })
hi('Repeat', { fg = p.red })
hi('Label', { fg = p.blue_soft })
hi('Operator', { fg = p.red })
hi('Keyword', { fg = p.red })
hi('Exception', { fg = p.red })
hi('PreProc', { fg = p.cyan_soft })
hi('Include', { fg = p.cyan_soft })
hi('Define', { fg = p.magenta })
hi('Macro', { fg = p.magenta })
hi('Type', { fg = p.blue_soft })
hi('StorageClass', { fg = p.green_soft })
hi('Structure', { fg = p.blue_soft })
hi('Typedef', { fg = p.blue_soft })
hi('Special', { fg = p.magenta })
hi('SpecialChar', { fg = p.magenta })
hi('Tag', { fg = p.cyan_soft })
hi('Delimiter', { fg = p.fg })
hi('Underlined', { fg = p.link, underline = true })
hi('Error', { fg = p.magenta_bright, bg = p.error_bg })
hi('Todo', { fg = p.yellow, bold = true })

-- Tree-sitter groups are ready for the later language-support slice.
hi('@comment', { link = 'Comment' })
hi('@string', { link = 'String' })
hi('@string.escape', { fg = p.magenta })
hi('@string.regexp', { fg = p.yellow })
hi('@string.special', { fg = p.orange })
hi('@keyword', { link = 'Keyword' })
hi('@keyword.operator', { link = 'Operator' })
hi('@constant', { link = 'Constant' })
hi('@number', { link = 'Number' })
hi('@boolean', { link = 'Boolean' })
hi('@variable', { fg = p.blue })
hi('@variable.builtin', { fg = '#4064bb' })
hi('@function', { link = 'Function' })
hi('@function.method', { link = 'Function' })
hi('@constructor', { fg = p.blue_soft })
hi('@type', { link = 'Type' })
hi('@type.builtin', { link = 'Type' })
hi('@attribute', { fg = p.cyan_soft })
hi('@property', { fg = p.blue_soft })
hi('@operator', { link = 'Operator' })
hi('@tag', { link = 'Tag' })
hi('@punctuation', { fg = p.fg })
hi('@markup.heading', { fg = p.blue_soft, bold = true })
hi('@markup.italic', { fg = p.yellow, italic = true })
hi('@markup.strong', { fg = p.yellow, bold = true })
hi('@markup.link.url', { fg = p.link, underline = true })
hi('@markup.link.label', { fg = '#e18964' })

-- Git and diagnostics
hi('DiffAdd', { fg = p.green, bg = p.string_bg })
hi('DiffChange', { fg = p.blue_soft, bg = p.hover })
hi('DiffDelete', { fg = p.error, bg = p.error_bg })
hi('DiffText', { fg = p.cyan, bg = p.selection, bold = true })
hi('Added', { fg = p.green })
hi('Changed', { fg = p.blue_soft })
hi('Removed', { fg = p.error })
hi('GitSignsAdd', { fg = p.green })
hi('GitSignsChange', { fg = p.blue_soft })
hi('GitSignsDelete', { fg = p.error })
hi('DiagnosticError', { fg = p.error })
hi('DiagnosticWarn', { fg = p.fg })
hi('DiagnosticInfo', { fg = p.blue_soft })
hi('DiagnosticHint', { fg = p.muted })
hi('DiagnosticUnderlineError', { undercurl = true, sp = p.error })
hi('DiagnosticUnderlineWarn', { undercurl = true, sp = p.yellow })
hi('DiagnosticUnderlineInfo', { undercurl = true, sp = p.blue_soft })
hi('DiagnosticUnderlineHint', { undercurl = true, sp = p.muted })

-- Telescope
hi('TelescopeNormal', { fg = p.fg, bg = p.elevated })
hi('TelescopeBorder', { fg = p.border_bright, bg = p.elevated })
hi('TelescopePromptNormal', { fg = p.fg, bg = p.surface })
hi('TelescopePromptBorder', { fg = p.border_bright, bg = p.surface })
hi('TelescopePromptPrefix', { fg = p.cyan, bg = p.surface })
hi('TelescopePromptTitle', { fg = p.bg, bg = p.cyan, bold = true })
hi('TelescopeResultsTitle', { fg = p.blue_soft, bg = p.elevated, bold = true })
hi('TelescopePreviewTitle', { fg = p.blue_soft, bg = p.elevated, bold = true })
hi('TelescopeSelection', { fg = p.fg, bg = p.hover, bold = true })
hi('TelescopeSelectionCaret', { fg = p.cyan, bg = p.hover })
hi('TelescopeMatching', { fg = p.cyan, bold = true })

-- Project sidebar
hi('NvimTreeNormal', { fg = p.fg, bg = p.surface })
hi('NvimTreeNormalNC', { fg = p.fg, bg = p.surface })
hi('NvimTreeWinSeparator', { fg = p.border, bg = p.surface })
hi('NvimTreeRootFolder', { fg = p.cyan, bg = p.surface, bold = true })
hi('NvimTreeFolderName', { fg = p.blue_soft, bg = p.surface })
hi('NvimTreeOpenedFolderName', { fg = p.cyan_soft, bg = p.surface })
hi('NvimTreeOpenedFile', { fg = p.cyan, bg = p.hover, bold = true })
hi('NvimTreeCursorLine', { bg = p.hover })
hi('NvimTreeGitDirty', { fg = p.gold })
hi('NvimTreeGitNew', { fg = p.green })
hi('NvimTreeGitDeleted', { fg = p.error })
hi('NvimTreeGitStaged', { fg = p.mint })
hi('NvimTreeIndentMarker', { fg = p.border })

-- Rendered Markdown
hi('RenderMarkdownH1', { fg = p.cyan, bold = true })
hi('RenderMarkdownH1Bg', { fg = p.cyan, bg = p.elevated, bold = true })
hi('RenderMarkdownH2', { fg = p.blue_soft, bold = true })
hi('RenderMarkdownH2Bg', { fg = p.blue_soft, bg = p.surface, bold = true })
hi('RenderMarkdownH3', { fg = p.gold, bold = true })
hi('RenderMarkdownH3Bg', { fg = p.gold, bg = p.surface, bold = true })
hi('RenderMarkdownH4', { fg = p.green, bold = true })
hi('RenderMarkdownH4Bg', { fg = p.green, bg = p.surface, bold = true })
hi('RenderMarkdownCode', { bg = p.string_bg })
hi('RenderMarkdownCodeInline', { fg = p.green, bg = p.string_bg })
hi('RenderMarkdownTableHead', { fg = p.cyan, bold = true })
hi('RenderMarkdownTableRow', { fg = p.fg })
hi('RenderMarkdownBullet', { fg = p.blue_soft })
hi('RenderMarkdownChecked', { fg = p.green })
hi('RenderMarkdownUnchecked', { fg = p.muted })
hi('RenderMarkdownLink', { fg = p.link, underline = true })
