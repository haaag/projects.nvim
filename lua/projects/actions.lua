local util = require('projects.util')
local store = require('projects.store')
local pathlib = require('projects.path')
local ok, fzf = pcall(require, 'fzf-lua')
if not ok then
  util.err('fzf-lua not installed. https://github.com/ibhagwan/fzf-lua')
  return
end

---@alias Action { title:string, keybind:string, fn:function, header:boolean }

---@return  Project[]
---@param t Project[]
local add_ansi = function(t)
  local ansi = fzf.utils.ansi_codes
  local width = 0
  for _, v in ipairs(t) do
    width = math.max(width, #v.name)
  end

  for _, p in ipairs(t) do
    local w = width
    local fmt = p.exists and ansi.magenta(p.name) or ansi.red(ansi.italic(p.name))
    local path_color = ansi.grey(ansi.italic(p.path))
    w = w + fzf.utils.ansi_escseq_len(fmt) + 2
    p.fmt = string.format('%-' .. w .. 's %s', fmt, path_color)
  end

  return t
end

local M = {}

M.command = _G.__fzf_projects.cmd

---@return boolean
---@param s table<string?>
function M.load_project(s)
  if s == nil then
    util.err('project not found')
    return false
  end

  local p = store.get(s[1])
  if p == nil then
    util.err('project not found')
    return false
  end

  if p.path == nil or p.path == '' then
    util.err('project not found')
    return false
  end

  local changed = pathlib.change_cwd(p.path)
  if not changed then
    return false
  end

  p.last_visit = os.time()
  store.update(p)

  return true
end

---@param s table<string?>
M.grep = function(s)
  if not M.load_project(s) then
    return
  end

  fzf.live_grep()
  fzf.actions.resume()
end

---@param s table<string?>
M.open = function(s)
  if not M.load_project(s) then
    return
  end

  fzf.files()
end

M.add = function(_)
  local root = pathlib.get_root()
  local name = vim.fs.basename(root)

  ---@type Project
  local project = {
    name = name,
    path = root,
    last_visit = os.time(),
  }

  store.insert(project)
  fzf.actions.resume()
end

---@param s table<string?>
M.remove = function(s)
  if s == nil then
    util.warn('project not found')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    return
  end

  store.remove(p)
  fzf.actions.resume()
end

M.restore = function(_)
  if not store.restore() then
    return
  end

  fzf.actions.resume()
end

---@param s table<string?>
M.rename = function(s)
  if s == nil then
    util.info('nothing to rename')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to rename')
    return
  end

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

  fzf.actions.resume()
end

---@param s table<string?>
M.edit_path = function(s)
  if s == nil then
    util.info('nothing to edit')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to edit')
    return
  end

  local prompt_opts = {
    prompt = 'New path: ',
    default = p.path,
  }

  vim.ui.input(prompt_opts, function(input)
    if not input or #input == 0 then
      return
    end
    store.edit_path(input, p)
  end)

  fzf.actions.resume()
end

---@return string
---@param act Action[]
M.create_header = function(act)
  local result = ''
  local sep = ' · '
  local count = 0
  for s, t in pairs(act) do
    count = count + 1
    if t.header then
      local key = string.format('%s:%s', t.keybind, s)
      if count == vim.tbl_count(act) then
        result = result .. key
      else
        result = result .. key .. sep
      end
    end
  end

  return result
end

---@return table
---@param act Action[]
M.load_actions = function(act)
  local result = {}
  for _, t in pairs(act) do
    result[t.keybind] = t.fn
  end

  return result
end

---@param opts table<any>
M.create_user_command = function(opts)
  vim.api.nvim_create_user_command(opts.cmd, function()
    fzf.fzf_exec(function(fzf_cb)
      local projects = store.data()
      projects = add_ansi(projects)

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

---@param opts table<any>
M.setup = function(opts)
  pathlib.touch(store.fname)
  M.create_user_command(opts)
end

return M
