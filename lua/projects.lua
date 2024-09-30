---@brief [[
---
---  ____            _           _
--- |  _ \ _ __ ___ (_) ___  ___| |_ ___
--- | |_) | '__/ _ \| |/ _ \/ __| __/ __|
--- |  __/| | | (_) | |  __/ (__| |_\__ \
--- |_|   |_|  \___// |\___|\___|\__|___/
---               |__/
---
---@brief ]]

local M = {}

M.name = 'projects.nvim'
M.cmd = 'Projects'

-- project's store
M.fname = vim.fn.stdpath('data') .. '/nvim-projects.txt'

-- export module
_G.__fzf_projects = M

M.actions = require('projects.actions')

---@type Action[]
local keybinds = {
  default = {
    title = 'default',
    keybind = 'default',
    fn = M.actions.open,
    header = false,
  },
  add = {
    title = 'add',
    keybind = 'ctrl-a',
    header = true,
    fn = M.actions.add,
  },
  grep = {
    title = 'grep',
    keybind = 'ctrl-g',
    header = true,
    fn = M.actions.grep,
  },
  rename = {
    title = 'rename',
    keybind = 'ctrl-r',
    header = true,
    fn = M.actions.rename,
  },
  restore = {
    title = 'restore',
    keybind = 'ctrl-u',
    header = true,
    fn = M.actions.restore,
  },
  remove = {
    title = 'remove',
    keybind = 'ctrl-x',
    header = true,
    fn = M.actions.remove,
  },
  edit_path = {
    title = 'edit path',
    keybind = 'ctrl-e',
    header = true,
    fn = M.actions.edit_path,
  },
}

M.setup = function(opts)
  M.actions.setup({
    prompt = opts.prompt or 'Projects> ',
    previewer = false,
    header = M.actions.create_header(keybinds),
    actions = M.actions.load_actions(keybinds),
    cmd = M.cmd,
  })
end

return M
