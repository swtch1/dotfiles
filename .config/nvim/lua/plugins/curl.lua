return {
	"oysandvik94/curl.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = { "CurlOpen" },
	config = function()
		local curl = require("curl")
		curl.setup({
			open_with = "split",
		})
	end,
}
