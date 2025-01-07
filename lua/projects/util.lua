---@param f string
---@return string, number
local function replace_home(f)
  local homeDir = os.getenv('HOME') or ''
  return f:gsub(homeDir, '~')
end

---@class Util
local M = {}

M.prefix = ''

---@param s string
M.info = function(s)
  local mesg = string.format('%s: %s', M.prefix, s)
  return vim.api.nvim_echo({ { mesg, 'Comment' } }, true, {})
end

---@param s string
M.warn = function(s)
  local mesg = string.format('%s: %s', M.prefix, s)
  return vim.api.nvim_echo({ { mesg, 'WarningMsg' } }, true, {})
end

---@param s string
M.err = function(s)
  local mesg = string.format('%s: %s', M.prefix, s)
  vim.api.nvim_echo({ { mesg, 'ErrorMsg' } }, true, {})
  error()
end

---@param s string
---@return table<string>
M.split_newline = function(s)
  local result = {}
  for line in string.gmatch(s, '[^\n]+') do
    table.insert(result, line)
  end
  return result
end

---@param projects Projects.Project[]
---@return Projects.Project[]
M.replace_home = function(projects)
  return vim.tbl_map(function(project)
    project.path = replace_home(project.path)
    return project
  end, projects)
end

---@param f string
---@return string
M.expand_tilde = function(f)
  local homeDir = os.getenv('HOME') or ''
  local p, _ = f:gsub('~', homeDir)
  return p
end

--- YYYY-MM-DD HH:MM:SS
---@param timestamp number
---@return string
M.format_last_visit = function(timestamp)
  local date = os.date('*t', timestamp)
  return string.format('%04d-%02d-%02d %02d:%02d:%02d', date.year, date.month, date.day, date.hour, date.min, date.sec)
end

-- convert to hex
---@param color number
---@return string
M.convert_to_hex = function(color)
  return string.format('#%06x', color)
end

---@param opts? Projects
M.setup = function(opts)
  opts = opts or {}
  M.prefix = opts.name
end

return M
