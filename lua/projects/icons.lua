local ok = require('fzf-lua.devicons').load()
if not ok then
  local errmsg = 'icons are enabled and no icons provider found'
  errmsg = errmsg .. '\nsupported icons provider:'
  errmsg = errmsg .. '\n  - mini.icons\t\thttps://github.com/echasnovski/mini.nvim'
  errmsg = errmsg .. '\n  - nvim-web-devicons\thttps://github.com/nvim-tree/nvim-web-devicons'
  require('projects.util').err(errmsg)
  return
end

local fzf = require('fzf-lua')
local util = require('projects.util')
local devicons = require('fzf-lua.devicons')
local M = {}

M.default_icon = ''
M.default_color = ''
M.warning = ''

---@param ft string
---@return string
M.get_color_by_ft = function(ft)
  local _, hl_name = devicons.icon_by_ft(ft)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name }) -- 0 for current window
  if not hl or not hl.fg then
    return M.default_color
  end

  return util.convert_to_hex(hl.fg)
end

---@return string
---@param ft string
M.get_by_ft = function(ft)
  return devicons.icon_by_ft(ft) or M.default_icon
end

---@return string
---@param ft string
M.color_by_ft = function(ft)
  if ft == 'default' then
    return M.default_color
  end

  return M.get_color_by_ft(ft)
end

---@return  Projects.Project[]
---@param t Projects.Project[]
---@param add_color boolean
M.load = function(t, add_color)
  for _, p in ipairs(t) do
    local icon = add_color and fzf.utils.ansi_from_rgb(M.color_by_ft(p.type), p.icon) or p.icon

    -- replace with warning icon if project does not exist
    if not p.exists then
      icon = add_color and fzf.utils.ansi_codes.red(M.warning) or M.warning
    end

    p.fmt = icon .. ' ' .. p.fmt
  end

  return t
end

---@param opts Projects.Icons
M.setup = function(opts)
  M.warning = opts.warning
  M.default_icon = opts.default
  local hl = vim.api.nvim_get_hl(0, { name = 'Normal' })
  M.default_color = opts.color or util.convert_to_hex(hl.fg)
end

return M
