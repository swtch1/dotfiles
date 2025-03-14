vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- better diff
vim.o.diffopt = "internal,filler,closeoff,linematch:60"

vim.opt.termguicolors = true

-- show whitespace
vim.opt.list = true
vim.opt.listchars = {
	space = '·',
	tab = '» ',
	lead = '·',
	trail = '·',
}

local function decorated_yank()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local numbered_lines = {}

	for i, line in ipairs(lines) do
		table.insert(numbered_lines, string.format("%d %s", start_line + i - 1, line))
	end

	local filename = vim.fn.expand("%")
	local decoration = string.rep('-', #filename + 1)
	local content = table.concat(numbered_lines, '\n')

	-- replace whitespace markers
	content = content:gsub('·', ' '):gsub('»', ' ')

	local result = decoration .. "\n" .. filename .. ":\n" .. decoration .. "\n" .. content
	vim.fn.setreg('+', result)
end
vim.keymap.set("v", "<c-y>", decorated_yank, { desc = "yank with line numbers" })

-- views can only be fully collapsed with the global statusline
-- recommended for avante.nvim but it messes up file names on statusline
-- vim.opt.laststatus = 3

do -- buffer changes
	vim.o.autoread = true
	-- load buffer changes on focus of that buffer
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
		callback = function()
			-- load buffers when nvim regains focus
			vim.cmd("checktime")
		end
	})
end

do -- macros
	local function set_comment_registers(style)
		-- format: [register, comment text]
		local markers = {
			{ 'f', 'FIXME: (JMT) ' },
			{ 'b', 'BOOKMARK: ' },
		}

		for _, pair in ipairs(markers) do
			local reg, text = pair[1], pair[2]
			vim.fn.setreg(reg, 'A ' .. style .. ' ' .. text)
		end
	end

	local comment_group = vim.api.nvim_create_augroup("set_comment_registers", { clear = true })

	-- Lua style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*.lua",
		callback = function() set_comment_registers("--") end,
		group = comment_group,
	})
	-- C-style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.go", "*.js", "*.ts", "*.c", "*.cpp", "*.java", "*.jsx", "*.tsx" },
		callback = function() set_comment_registers("//") end,
		group = comment_group,
	})
	-- Hash style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.py", "*.rb", "*.pl", "*.yaml", "*.yml", "*.sh", "*.zsh" },
		callback = function() set_comment_registers("#") end,
		group = comment_group,
	})
end

do -- mappings
	-- "run" actions (plugin specific mappings defined with plugin)
	vim.keymap.set("v", "<leader>re", "cx<esc>{o x := <esc>p^<esc><cmd>lua vim.lsp.buf.rename()<CR>",
		{ desc = "extract selection" })

	-- configuration
	vim.keymap.set("n", "<leader>rd", ":vsp /Users/josh/code/ss/.envrc.local<CR>", { desc = "edit env" })
	vim.keymap.set("n", "<leader>rD", ":vsp /Users/josh/.config/nvim/lua/plugins/dap.lua<CR>",
		{ desc = "edit debugger configuration" })

	-- modes
	vim.keymap.set("n", "<leader>mv", "<C-v>", { desc = "visual mode" })
	vim.keymap.set("n", "<leader>mw", ":set wrap!<CR>", { desc = "toggle wrap" })
	vim.keymap.set("n", "<leader>mn", ":set relativenumber!<CR>", { desc = "toggle relative number" })
	vim.keymap.set("n", "<leader>ml", "<cmd>lua vim.o.background='light'<CR>", { desc = "light mode" })

	-- buffers
	vim.keymap.set("n", "<leader>h", "<C-W>h", { desc = "move left" })
	vim.keymap.set("n", "<leader>j", "<C-W>j", { desc = "move down" })
	vim.keymap.set("n", "<leader>k", "<C-W>k", { desc = "move up" })
	vim.keymap.set("n", "<leader>l", "<C-W>l", { desc = "move right" })
	-- navigate to the leftmost or rightmost buffer window on the same row
	local function go_to_extreme_window(direction)
		local current_win = vim.api.nvim_get_current_win()
		local current_pos = vim.api.nvim_win_get_position(current_win)
		local current_col = current_pos[2]

		local windows = vim.api.nvim_list_wins()
		if #windows == 0 then
			return
		end

		local target_win = current_win
		local target_col = current_col

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

		vim.api.nvim_set_current_win(target_win)
	end
	vim.keymap.set("n", "<leader>H", function() go_to_extreme_window("left") end, { desc = "Go to leftmost window" })
	vim.keymap.set("n", "<leader>L", function() go_to_extreme_window("right") end, { desc = "Go to rightmost window" })
	vim.keymap.set("n", "<leader><Esc>", "<C-W><C-P>", { desc = "move to last buffer" })
	vim.keymap.set("n", "<up>", ":resize -2<CR>", { desc = "resize window" })
	vim.keymap.set("n", "<down>", ":resize +2<CR>", { desc = "resize window" })
	vim.keymap.set("n", "<left>", ":vertical resize -5<CR>", { desc = "resize window" })
	vim.keymap.set("n", "<right>", ":vertical resize +5<CR>", { desc = "resize window" })
	vim.keymap.set("n", "<leader>ew", ":e %:p:h", { desc = "edit working dir" })
	vim.keymap.set("n", "<leader>es", ":sp %:p:h<CR>", { desc = "split working dir" })
	vim.keymap.set("n", "<leader>ev", ":vsp %:p:h<CR>", { desc = "vsplit working dir" })
	vim.keymap.set("n", "<leader>bm", ":WinShift<CR>", { desc = "move buffer" })
	vim.keymap.set("n", "<BS>", ":e#<CR>", { desc = "previous buffer" })
	vim.keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "delete buffer" })
	vim.keymap.set("n", "<leader>bD", ":bd!<CR>", { desc = "force delete buffer" })
	vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "quit buffer" })
	vim.keymap.set("n", "<leader>Q", ":qa<CR>", { desc = "quit all" })
	vim.keymap.set("n", "<leader>O", ":only<CR>:noh<CR>", { desc = "close all other buffers" })
	vim.keymap.set("n", "<leader>o", ":lclose<CR>:cclose<CR>:Trouble close<CR>:silent! BuffergatorClose<CR>:noh<CR>",
		{ desc = "cleanup temp buffers", silent = true })
	vim.keymap.set("n", "<leader>rl", ":checktime<CR>", { desc = "reload buffers", silent = true })
end
