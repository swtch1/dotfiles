-- buffers
if vim.g.vscode then
	vim.keymap.set("n", "<leader>h",
		function() vim.fn.VSCodeNotify("workbench.action.navigateLeft") end,
		{ desc = "move left" })
	vim.keymap.set("n", "<leader>j",
		function() vim.fn.VSCodeNotify("workbench.action.navigateDown") end,
		{ desc = "move down" })
	vim.keymap.set("n", "<leader>k",
		function() vim.fn.VSCodeNotify("workbench.action.navigateUp") end,
		{ desc = "move up" })
	vim.keymap.set("n", "<leader>l",
		function() vim.fn.VSCodeNotify("workbench.action.navigateRight") end,
		{ desc = "move right" })
end
