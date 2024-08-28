-- return {
-- 	"oysandvik94/curl.nvim",
-- 	cmd = { "CurlOpen" },
-- 	dependencies = {
-- 		"nvim-lua/plenary.nvim",
-- 	},
-- 	keys = {
-- 		{ "<leader>rc", "<cmd>CurlOpen<cr><cmd>tabclose<cr>", desc = "Run curl cmd" },
-- 	},
-- 	config = true,
-- }
return {
	"oysandvik94/curl.nvim",
	branch = "open_in_split",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local curl = require("curl")
		curl.setup({
			open_with = "split",
		})
	end
}
