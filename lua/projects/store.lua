local util = require('projects.util')
local pathlib = require('projects.path')
local M = {}

---@alias Project { name:string, path:string, fmt:string, last_visit:integer, exists:boolean }

M.file = _G.__fzf_projects.fname

---@type Project[]
M.state = {}

---@return Project[]
M.data = function()
  local lines = pathlib.read(M.file)
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

---@param p string
M.add = function(p)
  local name = vim.fs.basename(p)
  local project = {
    name = name,
    path = p,
    last_visit = os.time(),
  }

  local data = M.data()
  M.save_state(data)

  if M.exists(project) then
    util.warn(string.format("'%s' already exists", project.name))
    return
  end

  pathlib.append(M.file, project)
end

---@param p Project
M.remove = function(p)
  local data = M.data()
  local projects = M.filter(data, p)
  M.save_state(data)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.file, projects_fmt)
  util.info(string.format("'%s' deleted", p.name))
end

---@param p Project
M.update = function(p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)
  table.insert(projects, p)

  local projects_fmt = util.fmt_to_str(projects)
  pathlib.write(M.file, projects_fmt)
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
  pathlib.write(M.file, projects_fmt)
  return p
end

M.restore = function()
  if M.state == nil or vim.tbl_isempty(M.state) then
    util.warn('nothing to undo')
    return
  end

  local projects_fmt = util.fmt_to_str(M.state)
  pathlib.write(M.file, projects_fmt)
  util.info('state restored')
end

---@return Project
---@param s string
M.get = function(s)
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

  ---@diagnostic disable-next-line: return-type-mismatch
  return project
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
