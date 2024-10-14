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
---@param add_icons boolean
---@param add_color boolean
local add_ansi = function(t, add_color, add_icons)
  t = util.replace_home(t)
  local ansi = fzf.utils.ansi_codes

  -- calculate maximum width based on project names
  local widths = vim.tbl_map(function(p)
    return #p.name
  end, t)
  local width = math.max(unpack(widths))

  local format_name = function(p)
    if add_color then
      local name
      if add_icons then
        local color = require('projects.icons').color_by_ft(p.type)
        name = p.exists and fzf.utils.ansi_from_rgb(color, p.name) or ansi.red(p.name)
      else
        name = p.exists and ansi.cyan(p.name) or ansi.red(p.name)
      end
      return name
    else
      return p.name
    end
  end

  for _, p in ipairs(t) do
    local name = format_name(p)
    local path_color = p.exists and ansi.italic(p.path) or ansi.grey(p.path .. ' (not found)')
    local w = width + fzf.utils.ansi_escseq_len(name) + 2
    p.fmt = string.format('%-' .. w .. 's %s', name, path_color)
  end

  return t
end

---@class Actions
local M = {
  fzf_files = fzf.files,
  fzf_live_grep = fzf.live_grep,
  fzf_resume = fzf.actions.resume,
}

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

  M.fzf_live_grep()
  M.fzf_resume()
end

---@param s table<string?>
M.open = function(s)
  if not M.load_project(s) then
    return
  end

  M.fzf_files()
end

M.add = function(_)
  local root = pathlib.get_root()
  local name = vim.fs.basename(root)

  ---@type Project
  local project = {
    name = name,
    path = root,
    last_visit = os.time(),
    type = 'default',
  }

  store.insert(project)
  M.fzf_resume()
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
  M.fzf_resume()
end

M.restore = function(_)
  if not store.restore() then
    return
  end

  M.fzf_resume()
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

  M.fzf_resume()
end

---@param s table<string?>
M.edit_path = function(s)
  if s == nil then
    util.info('nothing to edit')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to edit: ' .. s[1])
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

  M.fzf_resume()
end

---@param s table<string?>
M.edit_type = function(s)
  if s == nil then
    util.info('nothing to edit')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to edit: ' .. s[1])
    return
  end

  local prompt_opts = {
    prompt = 'New type: ',
    default = p.type,
  }

  vim.ui.input(prompt_opts, function(input)
    if not input or #input == 0 then
      return
    end
    store.edit_type(input, p)
  end)

  M.fzf_resume()
end

---@return string
---@param act Action[]
M.create_header = function(act)
  local result = ''
  local sep = ' '
  local count = 0
  local n = vim.tbl_count(act)
  for _, t in pairs(act) do
    count = count + 1
    if t.header then
      local key = string.format('%s:%s', fzf.utils.ansi_codes.yellow(t.keybind), t.title)
      if count == n then
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

---@param opts table
M.create_user_command = function(opts)
  vim.api.nvim_create_user_command(opts.cmd, function()
    fzf.fzf_exec(function(fzf_cb)
      local projects = store.data()
      projects = add_ansi(projects, opts.color, opts.icons.enabled)

      if opts.icons.enabled then
        projects = require('projects.icons').load(projects, opts.color)
      end

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

---@type Action[]
M.defaults = {
  enter = {
    title = 'default',
    keybind = 'default',
    fn = M.open,
    header = false,
  },
  add = {
    title = 'add',
    keybind = 'ctrl-a',
    header = true,
    fn = M.add,
  },
  grep = {
    title = 'grep',
    keybind = 'ctrl-g',
    header = true,
    fn = M.grep,
  },
  rename = {
    title = 'rename',
    keybind = 'ctrl-r',
    header = true,
    fn = M.rename,
  },
  restore = {
    title = 'restore',
    keybind = 'ctrl-u',
    header = true,
    fn = M.restore,
  },
  remove = {
    title = 'remove',
    keybind = 'ctrl-x',
    header = true,
    fn = M.remove,
  },
  edit_path = {
    title = 'edit path',
    keybind = 'ctrl-e',
    header = true,
    fn = M.edit_path,
  },
  edit_type = {
    title = 'edit type',
    keybind = 'ctrl-t',
    header = true,
    fn = M.edit_type,
  },
}

---@param opts table
M.setup = function(opts)
  opts.header = opts.header or M.create_header(M.defaults)
  opts.actions = vim.tbl_deep_extend('keep', opts.actions or {}, M.load_actions(M.defaults))
  M.create_user_command(opts)
end

return M
