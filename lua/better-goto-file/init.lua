local M = {}
local default_options = {
    gf_command = "gf",
    file_pattern = "[a-zA-Z0-9_/~.%-]+",
    line_pattern = "[: ]",
    column_pattern = "[: ]",
    number_pattern = "[0-9]+",
    message_on_error = true,
}

---@class better-goto-file.Options
---@field gf_command? string Normal mode command used to jump to the file
---@field file_pattern? string Pattern to match the file name
---@field line_pattern? string Pattern to match the line number separator
---@field column_pattern? string Pattern to match the column separator
---@field number_pattern? string Pattern to match the line number and column
---@field message_on_error? boolean Whether or not to print an error message if the goto file command fails

---@type better-goto-file.Options
M.opts = default_options

---@class better-goto-file.Match
---@field filename_end integer Last column of filename
---@field match_start integer First column of the match
---@field match_end integer Last column of the match
---@field line_number? integer Optional line number after the filename
---@field column? integer Optional column after the filename

---Go to file, line, and column under the cursor
---@param opts? better-goto-file.Options
M.goto_file = function(opts)
    opts = opts or {}
    local options = vim.tbl_deep_extend("keep", opts, M.opts)

    -- Get the cursor position
    local cursor_line, cursor_column = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_column = cursor_column + 1

    -- Get the line under the cursor
    local line = unpack(vim.api.nvim_buf_get_lines(
        0,
        cursor_line - 1,
        cursor_line,
        false
    ))

    ---@type better-goto-file.Match|nil
    local match

    ---@type integer|nil, integer|nil
    local match_start, match_end = 1, 0

    while true do
        match_start, match_end = string.find(line, options.file_pattern, match_end + 1)

        if not match_start or not match_end or match_start > cursor_column then
            match = nil

            if options.message_on_error then
                print("No filename under cursor")
            end

            break
        end

        match = {
            filename_end = match_end - 1,
            match_start = match_start,
            match_end = match_end,
        }

        ---Attempt to match the next pattern, advancing `match_end` on success
        ---@param pattern string Pattern to match
        ---@return string|nil text Matched text
        local function match_next(pattern)
            local remaining_line = line:sub(match_end + 1)
            local pattern_start, pattern_end = string.find(remaining_line, pattern)

            if pattern_start == 1 then
                local value = remaining_line:sub(pattern_start, pattern_end)
                match_end = match_end + pattern_end
                return value
            end
        end

        -- Try to match line number and column
        if match_next(options.line_pattern) then
            local line_number = match_next(options.number_pattern)

            if line_number then
                match.match_end = match_end
                match.line_number = tonumber(line_number)

                if match_next(options.column_pattern) then
                    local column = match_next(options.number_pattern)

                    if column then
                        match.match_end = match_end
                        match.column = tonumber(column) - 1
                    end
                end
            end
        end

        if match.match_start <= cursor_column and match.match_end >= cursor_column then
            -- Match found below cursor
            break
        end
    end

    if match then
        if cursor_column > match.filename_end then
            -- If the cursor is not directly on the filename, Neovims builtin `gF` doesn't execute the jump.
            -- So we move the cursor over the filename before running goto file.
            --
            -- ~/.config/nvim/init.lua:10:5
            --                          ^ cursor starts here
            --
            -- ~/.config/nvim/init.lua:10:5
            --                       ^ cursor will end up here
            --
            vim.api.nvim_win_set_cursor(0, { cursor_line, match.filename_end })
        end

        local command = vim.api.nvim_replace_termcodes(options.gf_command, true, true, true)
        local file_changed, error = pcall(vim.cmd, "norm! " .. command)

        -- It's possible for pcall to return false even though the file was found if an autocmd fails (for
        -- example if the buffer was unloaded and `BufReadPost` runs into an error). To avoid this edge case
        -- we also check if the error message contains the error code "E447", associated with a non-existent
        -- file. If it does not, we can assume that the error was unrelated to the `gF` command.
        file_changed = file_changed or (error:match("E447") == nil and error:match("E347") == nil)

        if not file_changed and options.message_on_error then
            print("Failed to go to file")
        end

        if file_changed and match.line_number then
            pcall(vim.api.nvim_win_set_cursor, 0, { match.line_number, match.column or 0 })
        end
    end
end

M.goto_file_range = function(opts)
    opts = opts or {}
    local options = vim.tbl_deep_extend("keep", opts, M.opts)

    local start_position = vim.fn.getpos("'<")
    local end_position = vim.fn.getpos("'>")

    local start_row, start_column = start_position[2], start_position[3]
    local end_row, end_column = end_position[2], end_position[3]

    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

    if #lines == 0 then
        return
    end

    local selected_text
    if #lines == 1 then
        selected_text = lines[1]:sub(start_column, end_column)
    else
        lines[1] = lines[1]:sub(start_column)
        lines[#lines] = lines[#lines]:sub(1, end_column)
        selected_text = table.concat(lines)
    end

    local trimmed_text = vim.trim(selected_text)

    -- Get the cursor position
    local cursor_line, cursor_column = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_column = cursor_column + 1

    ---@type integer|nil, integer|nil
    local match_start, match_end = string.find(trimmed_text, options.file_pattern)

    if not match_start then
        if options.message_on_error then
            print("No filename under cursor")
        end

        return
    end

    local start_offset = start_column - 1
    ---@type better-goto-file.Match
    local match = {
        filename_end = start_offset + match_end - 1,
        match_start = start_offset + match_start,
        match_end = start_offset + match_end,
    }

    ---Attempt to match the next pattern, advancing `match_end` on success
    ---@param pattern string Pattern to match
    ---@return string|nil text Matched text
    local function match_next(pattern)
        local remaining_line = trimmed_text:sub(match_end + 1)
        local pattern_start, pattern_end = string.find(remaining_line, pattern)

        if pattern_start == 1 then
            local value = remaining_line:sub(pattern_start, pattern_end)
            match_end = match_end + pattern_end
            return value
        end
    end

    -- Try to match line number and column
    if match_next(options.line_pattern) then
        local line_number = match_next(options.number_pattern)

        if line_number then
            match.match_end = match_end
            match.line_number = tonumber(line_number)

            if match_next(options.column_pattern) then
                local column = match_next(options.number_pattern)

                if column then
                    match.match_end = match_end
                    match.column = tonumber(column) - 1
                end
            end
        end
    end

    if start_row ~= cursor_line or cursor_column < match.match_start or cursor_column > match.filename_end then
        -- If the cursor is not directly on the filename, Neovims builtin `gF` doesn't execute the jump.
        -- So we move the cursor over the filename before running goto file.
        --
        -- ~/.config/nvim/init.lua:10:5
        --                          ^ cursor starts here
        --
        -- ~/.config/nvim/init.lua:10:5
        --                       ^ cursor will end up here
        --
        vim.api.nvim_win_set_cursor(0, { cursor_line, match.filename_end })
    end

    -- As of now the behavior here is a bit too forgiving. If only the second part of a path is selected
    -- this will call normal mode `gf` on the entire path, where as we would ideally only call the visual
    -- mode `gf` on the selection. Sadly there is no command for visual mode and feedkeys does not allow
    -- catching errors, so for now we have to live with the trade-off.
    local command = vim.api.nvim_replace_termcodes(options.gf_command, true, true, true)
    local file_changed, error = pcall(vim.cmd, "norm! " .. command)

    -- It's possible for pcall to return false even though the file was found if an autocmd fails (for
    -- example if the buffer was unloaded and `BufReadPost` runs into an error). To avoid this edge case
    -- we also check if the error message contains the error code "E447", associated with a non-existent
    -- file. If it does not, we can assume that the error was unrelated to the `gF` command.
    file_changed = file_changed or (error:match("E447") == nil and error:match("E347") == nil)

    if not file_changed and options.message_on_error then
        print("Failed to go to file")
    end

    if file_changed and match.line_number then
        pcall(vim.api.nvim_win_set_cursor, 0, { match.line_number, match.column or 0 })
    end
end

---@param opts? better-goto-file.Options
M.setup = function(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("keep", opts, default_options)

    vim.api.nvim_create_user_command("GotoFile", M.goto_file,
        { desc = "Goto file under cursor", force = false })
    vim.api.nvim_create_user_command("GotoFileRange", M.goto_file_range,
        { desc = "Goto file in selection", force = false })
end

return M
