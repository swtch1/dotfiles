vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

-- show whitespace
vim.opt.list = true
vim.opt.listchars = {
	space = '·',
	tab = '» ',
	lead = '·',
	trail = '·',
}

-- macros
vim.fn.setreg('d', 'yiwO// pA ')
vim.fn.setreg('b', 'A // BOOKMARK: ')
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.fn.setreg('f', "A // FIXME: (JMT) ")
		-- local fixme_strings = {
		-- 	go = "A // FIXME: (JMT) ",
		-- 	lua = "A -- FIXME: (JMT) ", -- doesn't work for some reason
		-- }
		-- local fixme = fixme_strings[vim.bo.filetype] or "A # FIXME: (JMT) "
		-- vim.fn.setreg('f', fixme)
	end
})

vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "quit buffer" })
vim.keymap.set("n", "<leader>Q", ":q!<CR>", { desc = "force quit buffer" })
vim.keymap.set("n", "<leader>v", "<C-v>", { desc = "visual mode" })
vim.keymap.set("n", "<leader>O", ":only<CR>:noh<CR>", { desc = "close all other buffers" })
vim.keymap.set("n", "<leader>o", ":lclose<CR>:cclose<CR>:noh<CR>:Trouble close<CR>", { desc = "cleanup quickfix" })
