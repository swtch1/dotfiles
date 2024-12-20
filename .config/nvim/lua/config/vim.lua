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

-- views can only be fully collapsed with the global statusline
-- recommended for avante.nvim but it messes up file names on statusline
-- vim.opt.laststatus = 3

-- macros
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
vim.keymap.set("n", "<leader>Q", ":qa<CR>", { desc = "quit all" })
vim.keymap.set("n", "<leader>v", "<C-v>", { desc = "visual mode" })
vim.keymap.set("n", "<leader>O", ":only<CR>:noh<CR>", { desc = "close all other buffers" })
vim.keymap.set("n", "<leader>o", ":lclose<CR>:cclose<CR>:noh<CR>:Trouble close<CR>", { desc = "cleanup quickfix" })

-- buffers
vim.keymap.set("n", "<leader>h", "<C-W>h", { desc = "move left" })
vim.keymap.set("n", "<leader>j", "<C-W>j", { desc = "move down" })
vim.keymap.set("n", "<leader>k", "<C-W>k", { desc = "move up" })
vim.keymap.set("n", "<leader>l", "<C-W>l", { desc = "move right" })
-- navigate to the leftmost or rightmost buffer window
local function go_to_extreme_window(direction)
	-- get a list of all open windows
	local windows = vim.api.nvim_list_wins()
	if #windows == 0 then
		return
	end

	-- initialize the target window with the first window in the list
	local target_win = windows[1]
	local target_col = vim.api.nvim_win_get_position(target_win)[2]

	-- iterate through all windows to find the extreme window based on the direction
	for _, win in ipairs(windows) do
		local pos = vim.api.nvim_win_get_position(win)
		local col = pos[2]

		if direction == "left" and col < target_col then
			target_win = win
			target_col = col
		elseif direction == "right" and col > target_col then
			target_win = win
			target_col = col
		end
	end

	-- Set the target window as the current window
	vim.api.nvim_set_current_win(target_win)
end
vim.keymap.set("n", "<leader>H", function() go_to_extreme_window("left") end, { desc = "Go to leftmost window" })
vim.keymap.set("n", "<leader>L", function() go_to_extreme_window("right") end, { desc = "Go to rightmost window" })
vim.keymap.set("n", "<leader><Esc>", "<C-W><C-P>", { desc = "move to last buffer" })
vim.keymap.set("n", "<up>", ":resize -2<CR>", { desc = "resize window" })
vim.keymap.set("n", "<down>", ":resize +2<CR>", { desc = "resize window" })
vim.keymap.set("n", "<left>", ":vertical resize -2<CR>", { desc = "resize window" })
vim.keymap.set("n", "<right>", ":vertical resize +2<CR>", { desc = "resize window" })
vim.keymap.set("n", "<leader>ew", ":e %:p:h", { desc = "edit working dir" })
vim.keymap.set("n", "<leader>es", ":sp %:p:h<CR>", { desc = "split working dir" })
vim.keymap.set("n", "<leader>ev", ":vsp %:p:h<CR>", { desc = "vsplit working dir" })
vim.keymap.set("n", "<leader>bm", ":WinShift<CR>", { desc = "move buffer" })
vim.keymap.set("n", "<BS>", ":e#<CR>", { desc = "previous buffer" })
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "delete buffer" })
vim.keymap.set("n", "<leader>bD", ":bd!<CR>", { desc = "force delete buffer" })
