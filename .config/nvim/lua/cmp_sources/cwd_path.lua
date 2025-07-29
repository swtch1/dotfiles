-- Custom nvim-cmp source for path completion relative to Neovim's working directory
-- Triggers on @ character to differentiate from normal path completion (. or /)

local cmp = require("cmp")

local source = {}

-- Constructor for the completion source
source.new = function()
	return setmetatable({}, { __index = source })
end

-- Define which characters trigger this completion source
-- @ is used to indicate paths relative to vim's cwd rather than current file
source.get_trigger_characters = function()
	return { "@" }
end

-- Pattern that matches valid completion keywords
-- Matches @ followed by any valid path characters
source.get_keyword_pattern = function()
	return [[@[0-9a-zA-Z\._\-/]*]]
end

-- This source is always available
source.is_available = function()
	return true
end

-- Main completion function called by nvim-cmp
source.complete = function(self, request, callback)
	local input = request.context.cursor_before_line:sub(request.offset)

	-- Only proceed if input starts with @
	if not input:match("^@") then
		callback({ items = {}, isIncomplete = false })
		return
	end

	-- Remove @ prefix and get the path part
	-- e.g., "@src/comp" -> "src/comp"
	local path_part = input:sub(2)
	local base_dir = vim.fn.getcwd()
	local search_dir = base_dir
	local prefix = ""

	-- Handle subdirectories by finding the last slash
	-- e.g., "src/comp" -> search in base_dir/src for items starting with "comp"
	local last_slash = path_part:match(".*()/")
	if last_slash then
		prefix = path_part:sub(1, last_slash) -- "src/"
		search_dir = base_dir .. "/" .. path_part:sub(1, last_slash - 1) -- base_dir/src
		path_part = path_part:sub(last_slash + 1) -- "comp"
	end

	-- Scan the directory for matching files/folders
	local items = {}
	local handle = vim.loop.fs_scandir(search_dir)

	if handle then
		while true do
			local name, type = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			-- Only include items that start with the typed prefix
			if name:sub(1, #path_part) == path_part then
				local is_dir = type == "directory"
				table.insert(items, {
					-- Keep the @ prefix in the completion menu
					label = "@" .. prefix .. name .. (is_dir and "/" or ""),
					insertText = "@" .. prefix .. name .. (is_dir and "/" or ""),
					kind = is_dir and cmp.lsp.CompletionItemKind.Folder or cmp.lsp.CompletionItemKind.File,
					data = { is_dir = is_dir },
				})
			end
		end
	end

	callback({ items = items, isIncomplete = false })
end

-- Resolution function (currently just passes through)
source.resolve = function(self, completion_item, callback)
	callback(completion_item)
end

return source
