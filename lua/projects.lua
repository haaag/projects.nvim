---@brief [[
---
---     ┏━┓┏━┓┏━┓ ┏┓┏━╸┏━╸╺┳╸┏━┓ ┏┓╻╻ ╻╻┏┳┓
---     ┣━┛┣┳┛┃ ┃  ┃┣╸ ┃   ┃ ┗━┓ ┃┗┫┃┏┛┃┃┃┃
---     ╹  ╹┗╸┗━┛┗━┛┗━╸┗━╸ ╹ ┗━┛╹╹ ╹┗┛ ╹╹ ╹
---
---     - keep your fun projects close by -
---
---@brief ]]

---@class Projects
local M = {
  name = 'projects.nvim',
  -- `user-command` in neovim.
  cmd = 'FzfLuaProjects',
  -- preview
  previewer = {
    enabled = true,
  },
  -- fzf's prompt
  prompt = 'Projects> ',
  -- icons
  icons = {
    default = '',
    warning = '',
    color = '#6d8086',
    enabled = true,
  },
  -- file store ($XDG_DATA_HOME/nvim || ~/.local/share/nvim)
  fname = vim.fn.stdpath('data') .. '/projects.json',
  -- color output
  color = true,
  -- keybinds
  keymap = {
    add = 'ctrl-a',
    edit_path = 'ctrl-e',
    edit_type = 'ctrl-t',
    grep = 'ctrl-g',
    remove = 'ctrl-x',
    rename = 'ctrl-r',
    restore = 'ctrl-u',
  },
}

---@param opts? Projects
M.setup = function(opts)
  opts = vim.tbl_deep_extend('keep', opts or {}, M)
  require('projects.util').setup(opts)
  require('projects.store').setup(opts)
  require('projects.actions').setup(opts)
  if opts.icons.enabled then
    require('projects.icons').setup(opts.icons)
  end
end

return M
