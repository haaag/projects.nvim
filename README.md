# 💥 Projects fzf

Simple [fzf-lua](https://github.com/ibhagwan/fzf-lua.git) project manager for [`neovim`](https://github.com/neovim/neovim/releases).

> [!WARNING]
> This is currently a work in progress, expect things to be broken!

<div align="left">
  <img align="center" src="assets/pic.png">
</div>

## ⚡️ Dependencies

- [`neovim`](https://github.com/neovim/neovim/releases) <small>version >=</small> `0.9.0`
- [`fzf-lua`](https://github.com/ibhagwan/fzf-lua) <small>neovim plug-in</small>
- [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons)
  <small><i><b>optional</b></i></small>

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'haaag/projects.nvim',
  dependencies = {
    "ibhagwan/fzf-lua",
    "nvim-tree/nvim-web-devicons", -- optional
  },
  opts = {},
  keys = {
    { '<leader>sp', '<CMD>FzfLuaProjects<CR>', desc = 'search projects' },
  },
  enabled = true,
}
```

<details>
<summary><strong>⚙️ Default configuration</strong></summary>

```lua
require('projects').setup({
  -- `user-command` in neovim
  cmd = 'FzfLuaProjects',
  -- file store ($XDG_DATA_HOME/nvim || ~/.local/share/nvim)
  fname = vim.fn.stdpath('data') .. '/projects.json',
  -- fzf's prompt
  prompt = 'Projects> ',
  -- preview
  previewer = {
    enabled = true,
  },
  -- icons
  icons = {
    default = '',
    warning = '',
    color = '#6d8086',
    enabled = true,
  },
  -- enable color output
  color = true,
  -- keybinds
  keymap = {
    add = 'ctrl-a',
    edit_path = 'ctrl-e',
    edit_type = 'ctrl-t',
    grep = 'ctrl-g',
    remove = 'ctrl-x',
    rename = 'ctrl-r',
    restore = 'ctrl-u',
  },
})
```

</details>
