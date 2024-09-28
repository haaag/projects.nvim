local util = require('projects.util')
local store = require('projects.store')
local pathlib = require('projects.path')
local ok, fzf_lua = pcall(require, 'fzf-lua')
if not ok then
  util.err('fzf-lua not installed. https://github.com/ibhagwan/fzf-lua')
  return
end

local M = {}

---@return  Project[]
---@param t Project[]
M.add_ansi = function(t)
  local ansi = fzf_lua.utils.ansi_codes
  local width = 0
  for _, v in ipairs(t) do
    width = math.max(width, #v.name)
  end

  for _, p in ipairs(t) do
    local w = width
    local fmt = p.exists and ansi.magenta(p.name) or ansi.red(ansi.bold(p.name))
    w = w + fzf_lua.utils.ansi_escseq_len(fmt) + 2
    p.fmt = string.format('%-' .. w .. 's %s', fmt, p.path)
  end

  return t
end

M.opts = {
  -- enter
  default = {
    function(item)
      local s = item[1]
      if s == nil then
        util.err('project not found')
        return
      end

      local project = store.get(s)
      if project.name == nil then
        util.err('project not found')
        return
      end

      local changed = pathlib.change_cwd(project.path)
      if not changed then
        return
      end

      project.last_visit = os.time()
      store.update(project)

      fzf_lua.files()
    end,
  },

  add = {
    function(_)
      store.add(pathlib.get_root())
    end,
    fzf_lua.actions.resume,
  },

  restore = {
    function(_)
      store.restore()
    end,
    fzf_lua.actions.resume,
  },

  remove = {
    function(s)
      store.remove(store.get(s[1]))
    end,
    fzf_lua.actions.resume,
  },

  rename = {
    function(item, _)
      local p = store.get(item[1])
      local prompt_opts = {
        prompt = 'Rename ' .. p.name .. ' to: ',
        default = p.name,
      }

      vim.ui.input(prompt_opts, function(input)
        if not input or #input == 0 then
          return
        end
        store.rename(input, p)
      end)
    end,
    fzf_lua.actions.resume,
  },
}

---@param opts table<any>
M.setup = function(opts)
  pathlib.touch(store.file)

  vim.api.nvim_create_user_command(_G.__fzf_projects.cmd, function()
    fzf_lua.fzf_exec(function(fzf_cb)
      local projects = store.data()
      projects = M.add_ansi(projects)

      table.sort(projects, function(a, b)
        return a.last_visit > b.last_visit
      end)

      for _, v in pairs(projects) do
        fzf_cb(v.fmt)
      end

      fzf_cb(nil) -- EOF
    end, opts)
  end, {})
end

return M
