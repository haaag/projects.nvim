# 💥 Projects fzf

> [!WARNING]
> This plugin is _beta_ quality. Expect breaking changes and many bugs

Simple [fzf-lua](https://github.com/ibhagwan/fzf-lua.git) project manager.


## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
	"haaag/projects.nvim",
	dependencies = { "ibhagwan/fzf-lua" },
	opts = {},
	keys = {
		{ "<leader>sp", "<CMD>FzfLuaProjects<CR>", desc = "search projects" },
	},
	enabled = true,
}
```

<details>
<summary><strong>Default configuration</strong></summary>

```lua
{
	-- `user-command` in neovim
	cmd = "FzfLuaProjects",
    -- file store ($XDG_DATA_HOME/nvim || ~/.local/share/nvim)
	fname = vim.fn.stdpath("data") .. "/nvim-projects.txt",
	-- fzf's prompt
	prompt = "Projects> ",
	-- preview (wip)
	previewer = false,
	-- icons
	icons = {
		default = "",
		warning = "",
		color = "#6d8086",
		enabled = true,
	},
	-- enable color output
	color = true,
}
```

</details>
