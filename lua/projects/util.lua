local M = {}

M.name = 'fzf-projects.nvim'

---@param s string
M.info = function(s)
  return vim.api.nvim_echo({ { M.name .. ': ' .. s, 'Comment' } }, true, {})
end

---@param s string
M.warn = function(s)
  return vim.api.nvim_echo({ { M.name .. ': ' .. s, 'WarningMsg' } }, true, {})
end

---@param s string
M.error = function(s)
  vim.api.nvim_echo({ { M.name .. ': ' .. s, 'ErrorMsg' } }, true, {})
end

---@param p Project
---@return string
M.fmt_line = function(p)
  return string.format('%s=%s=%s\n', p.name, p.path, p.last_visit)
end

---@param s string
---@return string, string
M.extract = function(s)
  local name, path = s:match('^(%S+)%s+(.+)$')
  return name or '', path or ''
end

---@return string[]
---@param t Project[]
M.fmt_to_str = function(t)
  local projects = {}
  for _, k in ipairs(t) do
    table.insert(projects, M.fmt_line(k))
  end

  return projects
end

---@param path string
---@return string
M.fmt_home_path = function(path)
  local h = os.getenv('HOME')
  if not h then
    return path
  end

  local s, _ = string.gsub(path, h, '~')
  return s
end

return M
