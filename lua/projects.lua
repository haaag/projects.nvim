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

M.setup = function(opts)
  local actions = require('projects.actions')
  local keybinds = actions.defaults
  actions.setup({
    prompt = opts.prompt or 'Projects> ',
    previewer = false,
    header = M.actions.create_header(keybinds),
    actions = M.actions.load_actions(keybinds),
    cmd = M.cmd,
  })
end

return M
