local util = require('projects.util')
local pathlib = require('projects.path')
local M = {}

---@alias Project { name:string, path:string, fmt:string, last_visit:integer, exists:boolean }

M.fname = _G.__fzf_projects.fname

---@type Project[]
M.state = {}

---@return Project[]
M.data = function()
  local lines = pathlib.read(M.fname)
  local projects = {}

  for _, l in pairs(lines) do
    local name = M.get_name(l)
    local path = M.get_path(l)
    local last = M.get_timestamp(l)

    table.insert(projects, {
      name = name,
      path = path,
      last_visit = last,
      exists = pathlib.exists(path),
    })
  end

  return projects
end

---@param p Project
M.insert = function(p)
  local data = M.data()
  M.save_state(data)

  if M.exists(p) then
    util.warn(string.format("'%s' already exists", p.name))
    return
  end

  pathlib.append(M.fname, p)
end

---@param p Project
M.remove = function(p)
  local data = M.data()
  local projects = M.filter(data, p)
  M.save_state(data)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.fname, projects_fmt)
  util.info(string.format("'%s' deleted", p.name))
end

---@param p Project
M.update = function(p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)
  table.insert(projects, p)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.fname, projects_fmt)
end

---@return boolean
---@param p Project
M.exists = function(p)
  local data = M.data()
  return vim.tbl_contains(data, function(v)
    return vim.deep_equal(v.path, p.path)
  end, { predicate = true })
end

---@return Project
---@param p Project
---@param new_name string
M.rename = function(new_name, p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)
  local old_name = p.name

  p.name = new_name
  util.info(string.format("project '%s' renamed to '%s'", old_name, new_name))
  table.insert(projects, p)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.fname, projects_fmt)
  return p
end

---@return Project
---@param p Project
---@param path string
M.edit_path = function(path, p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)

  p.path = path
  util.info(string.format("project '%s' new path '%s'", p.name, p.path))
  table.insert(projects, p)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.fname, projects_fmt)
  return p
end

---@return boolean
M.restore = function()
  if M.state == nil or vim.tbl_isempty(M.state) then
    util.warn('nothing to undo')
    return false
  end

  local projects_fmt = util.fmt_to_str(M.state)
  pathlib.write(M.fname, projects_fmt)
  util.info('state restored')

  return true
end

---@return Project?
---@param s string?
M.get = function(s)
  if type(s) ~= 'string' then
    util.warn('expected type string, got: ' .. type(s))
  end

  if s == nil then
    return
  end

  local projects = M.data()
  local project = nil
  local name, path = M.extract(s)

  if name == '' or path == '' then
    util.err(string.format("'%s' not found", s))
    return {}
  end

  for _, p in ipairs(projects) do
    if p.name == name and p.path == path then
      project = p
      break
    end
  end

  return project
end

---@return integer
---@param p Project
M.index = function(p)
  local data = M.data()
  for i, t in ipairs(data) do
    if t.name == p.name and t.path == p.path then
      return i
    end
  end

  return -1
end

---@param s string
M.get_name = function(s)
  if s == nil or s == '' then
    return ''
  end

  return s:match('^(.-)=') or 'name-not-found'
end

---@param s string
M.get_path = function(s)
  if s == nil or s == '' then
    return ''
  end

  return s:match('=(.+)=%d+$') or 'path-not-found'
end

---@param s string
M.get_timestamp = function(s)
  if s == nil or s == '' then
    return ''
  end
  return s:match('=(%d+)$') or '0'
end

---@return Project[]
---@param t Project[]
---@param target Project
M.filter = function(t, target)
  return vim.tbl_filter(function(k)
    return target.path ~= k.path
  end, t)
end

---@param p Project[]
M.save_state = function(p)
  M.state = vim.deepcopy(p)
end

---extract *name|path* from a string
---@param s string
---@return string, string
M.extract = function(s)
  local name, path = s:match('^(%S+)%s+(.+)$')
  return name or '', path or ''
end

return M
