local api = vim.api
local ts = vim.treesitter

local M = {}

local function expression_at_point(tsroot)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_node = tsroot:named_descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])
	return current_node
end

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

local function getCompletionItems(parser, prefix)
	local tstree = parser:parse():root()

	-- Get all identifiers
	local raw_query = [[
	(function_declarator declarator: (identifier) @func)
	(preproc_def name: (identifier) @preproc)
	(preproc_function_def name: (identifier) @preproc)
	(parameter_declaration declarator: (identifier) @param)
	(parameter_declaration declarator: (pointer_declarator declarator: (identifier) @param))
	(pointer_declarator declarator: (identifier) @var)
	(init_declarator declarator: (identifier) @var)
	(declaration declarator: (identifier) @var)
	]]

	local row_start, col_start, row_end, col_end = tstree:range()

	local tsquery = ts.parse_query(parser.lang, raw_query)

	-- local at_point = expression_at_point(tstree)

	local complete_items = {}

	for id, node in tsquery:iter_captures(tstree, parser.bufnr, row_start, row_end) do
		local name = tsquery.captures[id] -- name of the capture in the query
		local node_text = get_node_text(node)
		if string.sub(node_text, 1, #prefix) == prefix then
			table.insert(complete_items, {
				word = node_text,
				kind = 'TS : '..name,
				icase = 1,
				dup = 1,
				empty = 1,
			})
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
