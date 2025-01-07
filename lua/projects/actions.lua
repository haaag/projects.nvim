local util = require('projects.util')
local store = require('projects.store')
local pathlib = require('projects.path')
local ok, fzf = pcall(require, 'fzf-lua')
if not ok then
  util.err('fzf-lua not installed. https://github.com/ibhagwan/fzf-lua')
  return
end

local ansi = fzf.utils.ansi_codes

---@return string
---@param s table<string>
local function previewer(s)
  local p = store.get(s[1])
  if not p then
    return ''
  end

  return 'last visited: ' .. util.format_last_visit(p.last_visit)
end

---@return  Projects.Project[]
---@param t Projects.Project[]
---@param add_icons boolean
---@param add_color boolean
local add_ansi = function(t, add_color, add_icons)
  if vim.tbl_isempty(t) then
    return t
  end

  t = util.replace_home(t)

  -- calculate maximum width based on project names
  local widths = vim.tbl_map(function(p)
    return #p.name
  end, t)
  local width = math.max(unpack(widths))

  local format_name = function(p)
    if add_color then
      local name
      if add_icons then
        local color = require('projects.icons').color_by_ft(p.type)
        name = p.exists and fzf.utils.ansi_from_rgb(color, p.name) or ansi.red(p.name)
      else
        name = p.exists and ansi.cyan(p.name) or ansi.red(p.name)
      end
      return name
    else
      return p.name
    end
  end

  for _, p in ipairs(t) do
    local name = format_name(p)
    local path_color = p.exists and ansi.italic(p.path) or ansi.grey(p.path .. ' (not found)')
    local w = width + fzf.utils.ansi_escseq_len(name) + 2
    p.fmt = string.format('%-' .. w .. 's %s', name, path_color)
  end

  return t
end

---@class Projects.FzfAction
local M = {
  fzf_files = fzf.files,
  fzf_live_grep = fzf.live_grep,
  fzf_resume = fzf.actions.resume,
}

---@return boolean
---@param s table<string?>
function M.load_project(s)
  if s == nil then
    util.err('project not found')
    return false
  end

  local p = store.get(s[1])
  if p == nil then
    util.err('project not found')
    return false
  end

  if p.path == nil or p.path == '' then
    util.err('project not found')
    return false
  end

  local changed = pathlib.change_cwd(p.path)
  if not changed then
    return false
  end

  M.update_last_visit(p)

  return true
end

---@param s table<string?>
M.grep = function(s)
  if not M.load_project(s) then
    return
  end

  local p = store.get(s[1])
  if not p then
    return
  end

  M.fzf_live_grep({ cwd = p.path })
  M.fzf_resume()
end

---@param s table<string?>
M.open = function(s)
  if not M.load_project(s) then
    return
  end

  local p = store.get(s[1])
  if not p then
    return
  end

  M.fzf_files({ cwd = p.path })
end

M.add = function(_)
  local root = pathlib.get_root()
  local name = vim.fs.basename(root)

  ---@type Projects.Project
  local project = {
    name = name,
    path = root,
    last_visit = os.time(),
    type = 'default',
  }

  store.insert(project)
  M.fzf_resume()
end

---@param s table<string?>
M.remove = function(s)
  if s == nil then
    util.warn('project not found')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    return
  end

  store.remove(p)
  M.fzf_resume()
end

M.restore = function(_)
  if not store.restore() then
    return
  end

  M.fzf_resume()
end

---@param s table<string?>
M.rename = function(s)
  if s == nil then
    util.info('nothing to rename')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to rename')
    return
  end

  local prompt_opts = {
    prompt = 'Rename ' .. p.name .. ' to: ',
    default = p.name,
  }

  vim.ui.input(prompt_opts, function(input)
    if not input or #input == 0 then
      return
    end
    store.rename(input, p)
  end)

  M.fzf_resume()
end

---@param s table<string?>
M.edit_path = function(s)
  if s == nil then
    util.info('nothing to edit')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to edit: ' .. s[1])
    return
  end

  local prompt_opts = {
    prompt = 'New path: ',
    default = p.path,
  }

  vim.ui.input(prompt_opts, function(input)
    if not input or #input == 0 then
      return
    end
    store.edit_path(input, p)
  end)

  M.fzf_resume()
end

---@param s table<string?>
M.edit_type = function(s)
  if s == nil then
    util.info('nothing to edit')
    return
  end

  local p = store.get(s[1])
  if p == nil then
    util.info('nothing to edit: ' .. s[1])
    return
  end

  local prompt_opts = {
    prompt = 'New type: ',
    default = p.type,
  }

  vim.ui.input(prompt_opts, function(input)
    if not input or #input == 0 then
      return
    end
    store.edit_type(input, p)
  end)

  M.fzf_resume()
end

---@param p Projects.Project
M.update_last_visit = function(p)
  p.last_visit = os.time()
  store.update(p)
end

---@return string
---@param act Projects.Action[]
M.create_header = function(act)
  local result = ''
  local sep = ' '
  local count = 0
  local n = vim.tbl_count(act)
  for _, t in pairs(act) do
    count = count + 1
    if t.header then
      local key = string.format('%s:%s', fzf.utils.ansi_codes.yellow(t.keybind), t.title)
      if count == n then
        result = result .. key
      else
        result = result .. key .. sep
      end
    end
  end

  return result
end

---@return table
---@param act Projects.Action[]
M.load_actions = function(act)
  local result = {}
  if vim.tbl_isempty(act) then
    return result
  end

  for _, t in pairs(act) do
    if t.fn and t.keybind then
      result[t.keybind] = t.fn
    end
  end

  return result
end

---@param opts Projects
M.load = function(opts)
  fzf.fzf_exec(function(fzf_cb)
    local projects = store.data()
    projects = add_ansi(projects, opts.color, opts.icons.enabled)

    if opts.icons.enabled then
      projects = require('projects.icons').load(projects, opts.color)
    end

    table.sort(projects, function(a, b)
      return a.last_visit > b.last_visit
    end)

    for _, v in pairs(projects) do
      fzf_cb(v.fmt)
    end

    fzf_cb(nil) -- EOF
  end, opts.fzf)
end

---@class Projects.Action
---@field title string: title of the action.
---@field keybind string: keybinding for the action.
---@field fn function: function to execute for the action.
---@field header boolean: indicates whether the action's description should be displayed in the header.

---@class Projects.DefaultsActions
---@field enter Projects.Action: default action.
---@field add Projects.Action: action to add.
---@field edit_path Projects.Action: action to edit the path.
---@field edit_type Projects.Action: action to edit the type.
---@field grep Projects.Action: action to grep.
---@field remove Projects.Action: action to remove.
---@field rename Projects.Action: action to rename.
---@field restore Projects.Action: action to restore.

---@param keymap Projects.Keymaps: keymap for the project actions.
---@return Projects.DefaultsActions: default configuration of actions.
M.defaults = function(keymap)
  return {
    enter = {
      title = 'default',
      keybind = 'default',
      fn = M.open,
      header = false,
    },
    add = {
      title = 'add',
      keybind = keymap.add,
      header = true,
      fn = M.add,
    },
    edit_path = {
      title = 'path',
      keybind = keymap.edit_path,
      header = true,
      fn = M.edit_path,
    },
    edit_type = {
      title = 'type',
      keybind = keymap.edit_type,
      header = true,
      fn = M.edit_type,
    },
    grep = {
      title = 'grep',
      keybind = keymap.grep,
      header = true,
      fn = M.grep,
    },
    remove = {
      title = 'remove',
      keybind = keymap.remove,
      header = true,
      fn = M.remove,
    },
    rename = {
      title = 'rename',
      keybind = keymap.rename,
      header = true,
      fn = M.rename,
    },
    restore = {
      title = 'restore',
      keybind = keymap.restore,
      header = true,
      fn = M.restore,
    },
  }
end

---@param opts? Projects
M.setup = function(opts)
  opts.header = opts.header or M.create_header(M.defaults(opts.keymap))
  opts.actions = vim.tbl_deep_extend('keep', opts.actions or {}, M.load_actions(M.defaults(opts.keymap)))
  if opts.previewer.enabled then
    opts.fzf_opts = {
      ['--preview'] = previewer,
      ['--preview-window'] = 'nohidden,down,10%,border-top,+{3}+3/3,~3',
    }
  end
  -- remove key, conflict with `fzf-lua`
  opts.previewer = nil

  M.create_user_command(opts)
end

return M
