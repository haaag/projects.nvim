---@brief [[
---
---     ┏━┓┏━┓┏━┓ ┏┓┏━╸┏━╸╺┳╸┏━┓ ┏┓╻╻ ╻╻┏┳┓
---     ┣━┛┣┳┛┃ ┃  ┃┣╸ ┃   ┃ ┗━┓ ┃┗┫┃┏┛┃┃┃┃
---     ╹  ╹┗╸┗━┛┗━┛┗━╸┗━╸ ╹ ┗━┛╹╹ ╹┗┛ ╹╹ ╹
---
---     - keep your fun projects close by -
---
---@brief ]]

---@class Projects.Project
---@field name string: project name
---@field path string: project path
---@field fmt string?: fzf's string format
---@field last_visit integer?: last visit
---@field exists boolean?: project exists
---@field type string: project type
---@field icon string?: project icon

---@class Projects.Icons
---@field default string: default icon
---@field warning string: default warning icon if project does not exist
---@field color string?: default icon color
---@field enabled boolean: enable icons

---@class Projects.Keymaps
---@field add string: add project
---@field edit_path string: edit project path
---@field edit_type string: edit project type
---@field grep string: grep in project path
---@field remove string: remove project
---@field rename string: rename project
---@field restore string: restore state

---@class Projects.FzfOpts
---@field header string: fzf header
---@field actions Projects.Action[]: fzf actions
---@field fzf_opts table: fzf options

---@class Projects
---@field name string: plugin name
---@field cmd string: `user-command` in neovim.
---@field previewer { enabled: boolean }: enable previewer
---@field prompt string: fzf's prompt
---@field fname string: file store ($XDG_DATA_HOME/nvim or ~/.local/share/nvim)
---@field color boolean: enable color output
---@field icons Projects.Icons: projects icons
---@field keymap Projects.Keymaps: fzf's keybinds
---@field fzf Projects.FzfOpts: fzf's options
local M = {
  name = 'projects.nvim',
  cmd = 'FzfLuaProjects',
  previewer = {
    enabled = true,
  },
  prompt = 'Projects> ',
  icons = {
    default = '',
    warning = '',
    color = nil,
    enabled = true,
  },
  fname = vim.fn.stdpath('data') .. '/projects.json',
  color = true,
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
  vim.api.nvim_create_user_command(M.cmd, function()
    opts = vim.tbl_deep_extend('keep', opts or {}, M)
    require('projects.util').setup(opts)
    if opts.icons.enabled then
      -- check if user installed a icons provider
      local ok, _ = pcall(require, 'projects.icons')
      if not ok then
        return
      end
      require('projects.icons').setup(opts.icons)
    end
    require('projects.store').setup(opts)
    require('projects.actions').setup(opts)
  end, {})
end

return M
