-- pre config is meant to be run before plugin initialization

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- better diff
vim.o.diffopt = "internal,filler,closeoff,linematch:60"

vim.opt.termguicolors = true

-- show whitespace
vim.opt.list = true
vim.opt.listchars = {
	space = "·",
	tab = "» ",
	lead = "·",
	trail = "·",
}

vim.opt.compatible = false
vim.opt.wrap = false
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.swapfile = false
vim.opt.title = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.encoding = "utf-8"
vim.opt.updatetime = 100
vim.opt.splitright = true
vim.opt.timeoutlen = 350
vim.opt.ttimeoutlen = 0
vim.opt.shortmess:remove("S")
vim.opt.shortmess:append("c")
vim.opt.scrolloff = 3
vim.opt.visualbell = true
vim.opt.history = 10000
vim.opt.wildignorecase = true
vim.opt.relativenumber = true
vim.opt.hidden = true
vim.opt.completeopt = { "menuone", "menu", "longest", "preview" }
vim.opt.wildmenu = true
vim.opt.wildmode = { "longest", "list", "full" }
vim.opt.mouse = "a"
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.foldlevel = 99
vim.opt.textwidth = 80
vim.opt.formatoptions = "cr/qnj"

local function decorated_yank()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local numbered_lines = {}

	for i, line in ipairs(lines) do
		table.insert(numbered_lines, string.format("%d %s", start_line + i - 1, line))
	end

	local filename = vim.fn.expand("%")
	local decoration = string.rep("-", #filename + 1)
	local content = table.concat(numbered_lines, "\n")

	-- replace whitespace markers
	content = content:gsub("·", " "):gsub("»", " ")

	local result = decoration .. "\n" .. filename .. ":\n" .. decoration .. "\n" .. content
	vim.fn.setreg("+", result)
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
		end,
	})
end

do -- macros
	local function set_comment_registers(prefix, suffix)
		-- format: [register, comment text]
		local markers = {
			{ "f", "FIXME: (JMT) " },
			{ "b", "BOOKMARK: " },
		}

		for _, pair in ipairs(markers) do
			local reg, text = pair[1], pair[2]
			vim.fn.setreg(reg, "A " .. prefix .. " " .. text .. suffix)
		end
	end

	local comment_group = vim.api.nvim_create_augroup("set_comment_registers", { clear = true })

	-- c-style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.go", "*.js", "*.ts", "*.c", "*.cpp", "*.java", "*.jsx", "*.tsx" },
		callback = function()
			set_comment_registers("//", "")
		end,
		group = comment_group,
	})
	-- hash style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.py", "*.rb", "*.pl", "*.yaml", "*.yml", "*.sh", "*.zsh" },
		callback = function()
			set_comment_registers("#", "")
		end,
		group = comment_group,
	})
	-- lua style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*.lua",
		callback = function()
			set_comment_registers("--", "")
		end,
		group = comment_group,
	})
	-- markdown style comments
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*.md",
		callback = function()
			set_comment_registers("<!--", "-->")
		end,
		group = comment_group,
	})
end

do -- mappings
	local function get_visible_buffer_paths()
		local wins = vim.api.nvim_tabpage_list_wins(0)
		local seen = {}
		local file_paths = {}
		for _, win in ipairs(wins) do
			local buf = vim.api.nvim_win_get_buf(win)
			if not seen[buf] then
				seen[buf] = true
				local fname_abs = vim.api.nvim_buf_get_name(buf)
				-- filter out ones we don't want
				if fname_abs ~= "" and not string.find(fname_abs, "zsh") then
					-- convert to relative path
					local fname_rel = vim.fn.fnamemodify(fname_abs, ":.")
					table.insert(file_paths, fname_rel)
				end
			end
		end
		return file_paths
	end

	-- "run" actions (plugin specific mappings defined with plugin)
	vim.keymap.set(
		"v",
		"<leader>re",
		"cx<esc>{o x := <esc>p^<esc><cmd>lua vim.lsp.buf.rename()<CR>",
		{ desc = "extract selection" }
	)
	vim.keymap.set("n", "<leader>re", ":e<CR>", { desc = "update buffer" })
	vim.keymap.set("n", "<leader>rl", ":Lazy update<CR>", { desc = "run :Lazy update" })
	vim.keymap.set("n", "<leader>rd", ":vsp /Users/josh/code/ss/.envrc.local<CR>", { desc = "edit env" })
	vim.keymap.set(
		"n",
		"<leader>rD",
		":vsp /Users/josh/.config/nvim/lua/plugins/dap.lua<CR>",
		{ desc = "edit debugger configuration" }
	)
	vim.keymap.set("n", "<leader>rB", function()
		local current_buffer_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
		if current_buffer_path ~= "" then
			local line_number = vim.fn.line(".")
			local result = "@" .. current_buffer_path .. " line " .. line_number
			vim.fn.setreg("+", result)
		else
			vim.notify("no file name for current buffer.", vim.log.levels.WARN)
		end
	end, { desc = "copy current buffer path with line number to clipboard" })
	vim.keymap.set("n", "<leader>rb", function()
		local current_buffer_path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
		if current_buffer_path ~= "" then
			vim.fn.setreg("+", "@" .. current_buffer_path)
		else
			vim.notify("no file name for current buffer.", vim.log.levels.WARN)
		end
	end, { desc = "copy current buffer path with @ prefix to clipboard" })

	-- modes
	vim.keymap.set("n", "<leader>mv", "<C-v>", { desc = "visual mode" })
	vim.keymap.set("n", "<leader>mw", ":set wrap!<CR>", { desc = "toggle wrap" })
	vim.keymap.set("n", "<leader>mn", ":set relativenumber!<CR>", { desc = "toggle relative number" })
	vim.keymap.set("n", "<leader>ml", "<cmd>lua vim.o.background='light'<CR>", { desc = "light mode" })
	vim.keymap.set("n", "<leader>mc", function()
		local files_to_open_raw = get_visible_buffer_paths()
		if #files_to_open_raw > 0 then
			local files_to_open_escaped = {}
			for _, fname in ipairs(files_to_open_raw) do
				table.insert(files_to_open_escaped, '"' .. vim.fn.fnameescape(fname) .. '"')
			end
			local command = "code -r . " .. table.concat(files_to_open_escaped, " ") .. " > /dev/null 2>&1"
			os.execute(command)
		end
	end, { desc = "open all visible buffers in VSCode" })

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
	vim.keymap.set("n", "<leader>H", function()
		go_to_extreme_window("left")
	end, { desc = "Go to leftmost window" })
	vim.keymap.set("n", "<leader>L", function()
		go_to_extreme_window("right")
	end, { desc = "Go to rightmost window" })
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
	vim.keymap.set(
		"n",
		"<leader>o",
		":lclose<CR>:cclose<CR>:Trouble close<CR>:silent! BuffergatorClose<CR>:noh<CR>",
		{ desc = "cleanup temp buffers", silent = true }
	)
end

do -- autocmds
	-- scroll all the way to the left when entering a buffer
	vim.api.nvim_create_autocmd("WinEnter", {
		pattern = "*",
		callback = function()
			vim.cmd("normal! 150zh")
		end,
	})

	-- disable syntax highlighting for treesitter debugging
	-- local go_syntax_off_group = vim.api.nvim_create_augroup("GoSyntaxOff", { clear = true })
	-- vim.api.nvim_create_autocmd("FileType", {
	-- 	group = go_syntax_off_group,
	-- 	pattern = "go",
	-- 	command = "syntax off",
	-- 	desc = "disable syntax highlighting for go files",
	-- })
end
