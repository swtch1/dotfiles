return {
	"oysandvik94/curl.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = { "CurlOpen" },
	keys = {
		{ "<leader>rc", "<cmd>CurlOpen<cr><cmd>tabclose<cr>", desc = "Run curl cmd" },
	},
	config = function()
		local curl = require("curl")
		curl.setup({
			open_with = "split",
		})
	end
}
