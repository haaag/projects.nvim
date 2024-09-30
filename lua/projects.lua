---@brief [[
---
---          ____            _           _
---         |  _ \ _ __ ___ (_) ___  ___| |_ ___
---         | |_) | '__/ _ \| |/ _ \/ __| __/ __|
---         |  __/| | | (_) | |  __/ (__| |_\__ \
---         |_|   |_|  \___// |\___|\___|\__|___/
---                     |__/
---
---          - keep your fun projects close by -
---@brief ]]

local M = {
  defaults = {
    name = 'projects.nvim',

    -- global `user-command` in neovim.
    cmd = 'Projects',

    -- fzf's prompt
    prompt = 'Projects> ',

    -- preview
    previewer = false,

    -- project's store
    fname = vim.fn.stdpath('data') .. '/nvim-projects.txt',
  },
}

---@param opts? table
M.setup = function(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend('keep', opts, M.defaults)
  require('projects.util').setup(opts)
  require('projects.store').setup(opts)
  require('projects.actions').setup(opts)
end

return M
