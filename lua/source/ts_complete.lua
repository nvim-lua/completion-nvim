local api = vim.api
local ts = vim.treesitter

local M = {}

local function expression_at_point(tsroot)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_node = tsroot:named_descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])
	return current_node
end

-- Copied from runtime treesitter.lua
local function get_node_text(node, bufnr)
	local start_row, start_col, end_row, end_col = node:range()
	if start_row ~= end_row then
		return nil
	end
	local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row+1, true)[1]
	return string.sub(line, start_col+1, end_col)
end

-- is dest in a parent of source
local function is_parent(source, dest)
	local current = source
	while current ~= nil do
		if current == dest then
			return true
		end

		current = current:parent()
	end

	return false
end

local function smallestContext(tree, parser, source)
	-- Step 1 get current context
	local contexts_query = ts.parse_query(parser.lang, [[
	((function_definition) @context)
	]])

	local row_start, col_start, row_end, col_end = tree:range()
	local contexts = {}

	for _, node in contexts_query:iter_captures(tree, parser.bufnr, row_start, row_end) do
		table.insert(contexts, node)
	end

	local current = source
	while not vim.tbl_contains(contexts, current) and current ~= nil do
		current = current:parent()
	end

	return current
end

local function getCompletionItems(parser, prefix)
	local tstree = parser:parse():root()

	-- Get all identifiers
	local ident_query = [[
	(function_declarator declarator: (identifier) @func)
	(preproc_def name: (identifier) @preproc)
	(preproc_function_def name: (identifier) @preproc)
	(parameter_declaration declarator: (identifier) @param)
	(parameter_declaration declarator: (pointer_declarator declarator: (identifier) @param))
	(array_declarator declarator: (identifier) @var)
	(pointer_declarator declarator: (identifier) @var)
	(init_declarator declarator: (identifier) @var)
	(declaration declarator: (identifier) @var)
	]]

	local row_start, col_start, row_end, col_end = tstree:range()

	local tsquery = ts.parse_query(parser.lang, ident_query)

	local at_point = expression_at_point(tstree)
	local context_here = smallestContext(tstree, parser, at_point)

	local complete_items = {}
	local found = {}

	-- Step 2 find correct completions
	for id, node in tsquery:iter_captures(tstree, parser.bufnr, row_start, row_end) do
		local name = tsquery.captures[id] -- name of the capture in the query
		local node_text = get_node_text(node)

		-- Only consider items in current scope, and not already met
		if node_text:sub(1, #prefix) == prefix 
			and (is_parent(node, context_here) or smallestContext(tstree, parser, node) == nil or name == "func")
			and not vim.tbl_contains(found, node_text) then
			table.insert(complete_items, {
				word = node_text,
				kind = 'TS : '..name,
				icase = 1,
				dup = 1,
				empty = 1,
			})
			table.insert(found, node_text)
		end
	end

	return complete_items
end

function M.triggerCompletion(manager, bufnr, prefix, textMatch)
	if api.nvim_buf_get_option(bufnr, 'ft') == 'c' then
		local parser = ts.get_parser(bufnr)
		local completions = getCompletionItems(parser, prefix)
		if #completions ~= 0 and manager.insertChar == true then
			vim.fn.complete(textMatch+1, completions)
			manager.insertChar = false
		else
			manager.changeSource = true
		end
	end
end

return M
