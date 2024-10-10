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
  defaults = {
    name = 'projects.nvim',

    -- global `user-command` in neovim.
    cmd = 'FzfLuaProjects',

    -- fzf's prompt
    prompt = 'Projects> ',

    -- preview
    previewer = false,

    -- project's store
    fname = vim.fn.stdpath('data') .. '/nvim-projects.txt',

    -- color output
    color = true,
  },
}

---@param opts? Projects
M.setup = function(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('keep', opts, M.defaults)
  require('projects.util').setup(opts)
  require('projects.store').setup(opts)
  require('projects.actions').setup(opts)
end

return M
