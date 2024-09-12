return {
	"aznhe21/actions-preview.nvim",
	lazy = false,
	config = function()
		local actions_preview = require("actions-preview")
		actions_preview.setup {
			backend = "telescope",
			telescope = {
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "bottom",
				},
			},
		}

		vim.keymap.set({ "v", "n" }, "<leader>ra", actions_preview.code_actions)
	end,
}
