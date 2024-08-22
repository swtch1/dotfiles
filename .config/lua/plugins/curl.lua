return {
	"oysandvik94/curl.nvim",
	cmd = { "CurlOpen" },
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>rc", "<cmd>CurlOpen<cr><cmd>tabclose<cr>", desc = "Run curl cmd" },
	},
	config = true,
}
