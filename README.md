# 💥 Projects fzf

Simple [fzf-lua](https://github.com/ibhagwan/fzf-lua.git) project manager.

- Install with [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
  {
    'haaag/projects.nvim',
    dependencies = { 'ibhagwan/fzf-lua' },
    lazy = true,
    opts = {
      prompt = 'Projects>> ',
      color = true,
    },
    keys = {
      { '<leader>sp', '<CMD>FzfLuaProjects<CR>', desc = 'search projects' },
    },
    enabled = true,
  }
```
