local util = require('projects.util')
local ok_icons, devicons = pcall(require, 'nvim-web-devicons')
if not ok_icons then
  util.warn('nvim-web-devicons not installed. https://github.com/nvim-tree/nvim-web-devicons')
  return
end

---@alias Icon { icon: string, color:string, name:string, cterm_color:string }
---@alias Opts { warning:string, default:string, color:string }

local M = {}

M.default_icon = ''
M.default_color = ''
M.warning = ''
M.all = nil

---@return string
---@param ft string
M.get_by_ft = function(ft)
  ---@type Icon?
  local i = M.get(ft)
  if i ~= nil then
    return i.icon
  end
  return devicons.get_icon_by_filetype(ft) or M.default_icon
end

---@return string
---@param ft string
M.color_by_ft = function(ft)
  if ft == 'default' then
    return M.default_color
  end

  ---@type Icon?
  local i = M.get(ft)
  if i ~= nil then
    return i.color
  end

  local _, color, _ = devicons.get_icon_colors_by_filetype(ft)
  return color or M.default_color
end

---@return Icon?
---@param s string
M.get = function(s)
  s = string.lower(s)
  for _, t in pairs(M.all) do
    if string.lower(t.name) == s then
      return t
    end
  end
end

---@return  Project[]
---@param t Project[]
---@param add_color boolean
M.load = function(t, add_color)
  local fzf = require('fzf-lua.utils')

  for _, p in ipairs(t) do
    local icon = add_color and fzf.ansi_from_rgb(M.color_by_ft(p.type), p.icon) or p.icon

    -- replace with warning icon if project does not exist
    if not p.exists then
      icon = add_color and fzf.ansi_codes.red(M.warning) or M.warning
    end

    p.fmt = icon .. ' ' .. p.fmt
  end

  return t
end

---@param opts Opts
M.setup = function(opts)
  M.all = devicons.get_icons()
  M.warning = opts.warning
  M.default_icon = opts.default
  M.default_color = opts.color
end

return M
