return {
	"nvim-telescope/telescope.nvim",
	branch = '0.1.x',
	dependencies = {
		'nvim-lua/plenary.nvim',
		'BurntSushi/ripgrep', -- optional
		'sharkdp/fd',       -- optional
	},
	lazy = true,
	keys = {
		{ '<leader>p',  '<cmd>Telescope find_files<cr>',                                                      desc = "Find files anywhere" },
		{ '<leader>P',  ':lua require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })<CR>', desc = "Find files in current dir" },
		{ '<leader>fa', '<cmd>Telescope live_grep<cr>',                                                       desc = "Live grep" },
		{ '<leader>fb', '<cmd>Telescope current_buffer_fuzzy_find<cr>',                                       desc = "Live grep current buffer" },
		{ '<leader>fA', ':lua require("telescope.builtin").live_grep({ cwd = vim.fn.expand("%:p:h") })<CR>',  desc = "Live grep in current dir" },
		{ '<leader>gu', ':lua require("telescope.builtin").lsp_implementations()<CR>',                        desc = "LSP implementations" },
		{ '<leader>gR', ':lua require("telescope.builtin").lsp_references()<CR>',                             desc = "LSP references" },
		{ '<leader>gT', ':lua require("telescope.builtin").lsp_incoming_calls()<CR>',                         desc = "LSP incoming calls" },
		{ '<leader>fF', ':lua require("telescope.builtin").grep_string({ search = "FIXME: (JMT)" })<CR>',     desc = "Grep FIXME (JMT)" },
		{ '<leader>fB', ':lua require("telescope.builtin").grep_string({ search = "BOOKMARK:" })<CR>',        desc = "Grep BOOKMARK:" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		telescope.setup({
			defaults = {
				-- send some or all entries to quickfix list with <C-q>
				mappings = {
					i = {
						["<C-q>"] = function(bufnr)
							actions.smart_send_to_qflist(bufnr)
							actions.open_qflist()
						end,
					},
					n = {
						["<C-q>"] = function(bufnr)
							actions.smart_send_to_qflist(bufnr)
							actions.open_qflist()
						end,
					},
				},
			},
		})
	end,
}
