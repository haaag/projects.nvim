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
  local data = pathlib.readfile(M.fname)
  local projects = {}

  for _, p in ipairs(data) do
    p.exists = pathlib.exists(p.path)

    -- add icon
    if M.icons then
      p.icon = require('projects.icons').get_by_ft(p.type)
    end

    table.insert(projects, p)
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

  table.insert(data, p)
  if not pathlib.writefile(M.fname, data) then
    return
  end

  util.info(string.format("project '%s' added", p.name))
end

---@param p Project
M.remove = function(p)
  local data = M.data()
  local projects = M.filter(data, p)
  M.save_state(data)

  pathlib.writefile(M.fname, projects)
  util.info(string.format("'%s' deleted", p.name))
end

---@param p Project
M.update = function(p)
  local data = M.data()
  M.save_state(data)
  local projects = M.filter(data, p)
  table.insert(projects, p)

  pathlib.writefile(M.fname, projects)
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

  pathlib.writefile(M.fname, projects)
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

  pathlib.writefile(M.fname, projects)
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

  pathlib.writefile(M.fname, projects)
  return p
end

---@return boolean
M.restore = function()
  if M.state == nil or vim.tbl_isempty(M.state) then
    util.warn('nothing to restore')
    return false
  end

  util.info('state restored')
  return pathlib.writefile(M.fname, M.state)
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
---@param s string?
---@return string, string
M.extract_name_path = function(s)
  if s == nil or s == '' then
    return '', ''
  end
  local _, name, path = s:match('^(%S*)%s*(%S+)%s+(.+)$')
  return name or '', path or ''
end

---@param opts { fname:string, icons:table }
M.setup = function(opts)
  if vim.fn.filereadable(opts.fname) == 0 then
    util.err("file not readable: '" .. opts.fname .. "'")
    return
  end

  M.fname = opts.fname
  M.icons = opts.icons.enabled
  pathlib.touch(opts.fname)
end

return M
