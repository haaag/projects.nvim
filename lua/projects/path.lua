local util = require('projects.util')
local uv = vim.uv or vim.loop

---@class Pathlib
local M = {}

---@return boolean
---@param fname string?
M.exists = function(fname)
  if fname == '' or fname == nil then
    return false
  end

  local file = io.open(fname, 'r')
  if file then
    file:close()
    return true
  else
    return false
  end
end

---@return boolean
---@param fname string?
---@param s string
M.append = function(fname, s)
  if fname == '' or fname == nil then
    util.err('append: filename can not be empty')
    return false
  end

  local file = io.open(fname, 'a')
  if not file then
    util.err('append: filename not found: ' .. fname)
    return false
  end

  file:write(s)
  file:close()

  return true
end

---@return Projects.Project[]
---@param fname string?
M.readfile = function(fname)
  if not fname or vim.fn.filereadable(fname) == 0 then
    return {}
  end

  local data = vim.fn.readfile(vim.fn.expand(fname))
  if vim.tbl_count(data) == 0 then
    return {}
  end

  return vim.fn.json_decode(data)
end

---@return boolean
---@param fname string
---@param t Projects.Project[]
M.writefile = function(fname, t)
  if vim.fn.filewritable(fname) == 0 then
    util.err("write: file: '" .. fname .. "' not writable")
    return false
  end

  if vim.tbl_isempty(t) then
    util.err('write: no data')
    return false
  end

  local data = vim.fn.json_encode(t)
  if not data then
    util.err('write: failed to encode data to JSON')
    return false
  end

  local success, err = pcall(vim.fn.writefile, { data }, fname)
  if not success then
    util.err('write: ' .. err)
  end

  return success
end

---@return boolean
---@param p string?
M.change_cwd = function(p)
  if p == nil then
    return false
  end

  if not M.exists(p) then
    util.err(p .. ' do not exists')
    return false
  end

  vim.fn.chdir(p)

  return true
end

---@param fname string?
M.touch = function(fname)
  if fname == '' or fname == nil then
    util.err('touch: filename can not be empty')
    return
  end

  if M.exists(fname) then
    return
  end

  local file = io.open(fname, 'w')
  if not file then
    return
  end

  file:close()
end

---@return boolean
---@param fname string?
M.path_is_directory = function(fname)
  local S_IFDIR = 0x4000 -- directory
  local stat = uv.fs_stat(fname)

  if stat and bit.band(stat.mode, 0xF000) == S_IFDIR then
    return true
  end
  return false
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@return string
function M.get_root()
  -- NOTE: extracted from `https://github.com/LazyVim/LazyVim`
  -- thanks @folke
  local root_patterns = { '.git', '/lua' }
  ---@type string?
  local path = vim.api.nvim_buf_get_name(0)
  path = path ~= '' and vim.loop.fs_realpath(path) or nil
  ---@type string[]
  local roots = {}
  if path then
    for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
      local workspace = client.config.workspace_folders
      local paths = workspace
          and vim.tbl_map(function(ws)
            return vim.uri_to_fname(ws.uri)
          end, workspace)
        or client.config.root_dir and { client.config.root_dir }
        or {}
      for _, p in ipairs(paths) do
        local r = vim.loop.fs_realpath(p)
        if path:find(r, 1, true) then
          roots[#roots + 1] = r
        end
      end
    end
  end
  table.sort(roots, function(a, b)
    return #a > #b
  end)
  ---@type string?
  local root = roots[1]
  if not root then
    root = vim.loop.cwd()
    -- path = path and vim.fs.dirname(path) or vim.loop.cwd()
    -- ---@type string?
    -- root = vim.fs.find(root_patterns, { path = path, upward = true })[1]
    -- root = root and vim.fs.dirname(root) or vim.loop.cwd()
  end
  ---@cast root string
  return root
end

return M
