return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "SmiteshP/nvim-navic" },
		opts = {
			options = {
				icons_enabled = false,
				theme = "papercolor_light",
				component_separators = { "", "" },
				section_separators = { "", "" },
				disabled_filetypes = {},
			},
			sections = {
				lualine_a = {},
				lualine_b = {
					{
						"filename",
						path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
					},
				},
				lualine_x = {},
				lualine_y = {},
				lualine_z = { "filetype" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1, shorting_target = 5 } },
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
			extensions = { "fzf" },
		},
		config = function(_, opts)
			local navic = require("nvim-navic")
			opts.sections.lualine_c = {
				{
					function()
						return navic.get_location()
					end,
					cond = navic.is_available,
				},
			}
			require("lualine").setup(opts)
		end,
	},
}
