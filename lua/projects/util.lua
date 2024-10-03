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

---@param str string
---@param target string
---@return boolean
M.startswith = function(str, target)
  return string.sub(str, 1, 1) == target
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

---@param opts {name:string}
M.setup = function(opts)
  M.prefix = opts.name
end

return M
