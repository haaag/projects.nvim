local util = require('projects.util')
local pathlib = require('projects.path')

---@class Store
local M = {}

---@alias Project { name:string, path:string, fmt:string, last_visit:integer, exists:boolean, type:string, icon:string }

---@type string?
M.fname = nil

---@type boolean
M.icons = false

---@type Project[]
M.state = {}

---@return Project[]
M.data = function()
  local lines = pathlib.read(M.fname)
  local projects = {}

  for _, l in pairs(lines) do
    local project = M.extract_project(l)
    project.exists = pathlib.exists(project.path)
    -- add icon
    if M.icons then
      project.icon = require('projects.icons').get_by_ft(project.type)
    end

    table.insert(projects, project)
  end

  return projects
end

---@param p Project
M.insert = function(p)
  local data = M.data()
  M.save_state(data)

  if M.exists(p) then
    util.warn('project already exists')
    return
  end

  local ok, p_formatted = pcall(M.fmt_line, p)
  if not ok then
    util.err('formating line before saving: ' .. p_formatted)
  end

  if not pathlib.append(M.fname, p_formatted) then
    util.err('error adding: ' .. p.name)
  end

  util.info(string.format("project '%s' added", p.name))
end

---@param p Project
M.remove = function(p)
  local data = M.data()
  local projects = M.filter(data, p)
  M.save_state(data)

  local projects_fmt = M.fmt_to_store(projects)
  pathlib.write(M.fname, projects_fmt)
  util.info(string.format("'%s' deleted", p.name))
end

---@param p Project
M.update = function(p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)
  table.insert(projects, p)

  local projects_fmt = M.fmt_to_store(projects)
  pathlib.write(M.fname, projects_fmt)
end

---@return boolean
---@param p Project
M.exists = function(p)
  local data = M.data()
  return vim.tbl_contains(data, function(v)
    return vim.deep_equal(v.path, p.path) or vim.deep_equal(v.name, v.path)
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

  local projects_fmt = M.fmt_to_store(projects)
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

  local projects_fmt = M.fmt_to_store(projects)
  pathlib.write(M.fname, projects_fmt)
  return p
end

---@return Project
---@param p Project
---@param new_type string
M.edit_type = function(new_type, p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)

  p.type = new_type
  util.info(string.format("project '%s' type '%s'", p.name, p.type))
  table.insert(projects, p)

  local projects_fmt = M.fmt_to_store(projects)
  pathlib.write(M.fname, projects_fmt)
  return p
end

---@return boolean
M.restore = function()
  if M.state == nil or vim.tbl_isempty(M.state) then
    util.warn('nothing to restore')
    return false
  end

  local projects_fmt = M.fmt_to_store(M.state)
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
  local name, path = M.extract_name_path(s)
  path = util.expand_tilde(path)

  if name == '' or path == '' then
    util.err(string.format("'%s' not found", s))
    return {}
  end

  for _, p in ipairs(projects) do
    if p.name == name or p.path == path then
      project = p
      break
    end
  end

  return project
end

---@return integer
---@param p Project
M.get_idx = function(p)
  local data = M.data()
  for i, t in ipairs(data) do
    if t.name == p.name and t.path == p.path then
      return i
    end
  end

  return -1
end

---@return Project
---@param s string
M.extract_project = function(s)
  -- line: project_name=path=last_visit=type
  local name, path, last_used, projecttype = s:match('([^=]+)=([^=]+)=([^=]+)=([^=]+)')
  return {
    name = name,
    path = path,
    last_visit = last_used,
    type = projecttype,
  }
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
M.extract_name_path = function(s)
  local _, name, path = s:match('^(%S*)%s*(%S+)%s+(.+)$')
  return name or '', path or ''
end

---@param p Project
---@return string
M.fmt_line = function(p)
  return string.format('%s=%s=%s=%s\n', p.name, p.path, p.last_visit, p.type)
end

---format items to store in file.
---@return string[]
---@param t Project[]
M.fmt_to_store = function(t)
  local projects = {}
  for _, k in ipairs(t) do
    table.insert(projects, M.fmt_line(k))
  end
  return projects
end

---@param opts { fname:string, icons:table }
M.setup = function(opts)
  M.fname = opts.fname
  M.icons = opts.icons.enabled
  pathlib.touch(opts.fname)
end

return M
