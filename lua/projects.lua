local M = {}

_G.__fzf_projects = {
  name = 'fzf-projects.nvim',
  cmd = 'Projects',
  fname = vim.fn.stdpath('data') .. '/nvim-projects.txt',
}

M.setup = function(opts)
  local actions = require('projects.actions')
  actions.setup({
    prompt = opts.prompt or 'Projects> ',
    previewer = false,
    header = '<ctrl-a>:add • <ctrl-x>:remove • <ctrl-r>:rename • <ctrl-u>:undo',
    actions = {
      ['default'] = actions.opts.default,
      ['ctrl-a'] = actions.opts.add,
      ['ctrl-u'] = actions.opts.restore,
      ['ctrl-x'] = actions.opts.remove,
      ['ctrl-r'] = actions.opts.rename,
    },
  })
end

return M
