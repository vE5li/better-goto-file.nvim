local M = {}
local default_config = {
    file_pattern = "[a-zA-Z_/~.%-]+",
    line_pattern = "[: ]",
    column_pattern = "[: ]",
    number_pattern = "[0-9]+",
    message_on_error = true,
}

---@class better-goto-file.Options
---@field file_pattern? string Pattern to match the file name
---@field line_pattern? string Pattern to match the line number separator
---@field column_pattern? string Pattern to match the column separator
---@field number_pattern? string Pattern to match the line number and column
---@field message_on_error? boolean Whether or not to print an error message if the goto file command fails

---@type better-goto-file.Options
M.opts = default_config

---Go to file, line, and column under the cursor
---@param opts? better-goto-file.Options
M.goto_file = function(opts)
    opts = opts or {}
    local config = vim.tbl_deep_extend("keep", opts, M.opts)

    local position = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_buf_get_lines(
            0,
            position[1] - 1,
            position[1],
            false
        )
        [1]
    local cursor_column = position[2] + 1
    local match

    ---@type integer|nil, integer|nil
    local start_pos, end_pos = 1, 0

    while true do
        start_pos, end_pos = string.find(line, config.file_pattern, end_pos + 1)

        if not start_pos or start_pos > cursor_column then
            print("No filename under cursor")
            match = { filename = nil };
            break
        end

        match = {
            filename = line:sub(start_pos, end_pos),
            filename_end = end_pos - 1,
            match_start = start_pos,
            match_end = end_pos,
            line_number = nil,
            colulmn = nil,
        }

        local function match_next(pattern)
            local remaining_line = line:sub(end_pos + 1)
            local match_start, match_end = string.find(remaining_line, pattern)

            if match_start == 1 then
                local value = remaining_line:sub(match_start, match_end)
                end_pos = end_pos + match_end
                return value
            end
        end

        if match_next(config.line_pattern) then
            local line_number = match_next(config.number_pattern)

            if line_number then
                match.match_end = end_pos
                match.line_number = tonumber(line_number)

                if match_next(config.column_pattern) then
                    local column = match_next(config.number_pattern)

                    if column then
                        match.match_end = end_pos
                        match.colulmn = tonumber(column)
                    end
                end
            end
        end

        if match.match_start <= cursor_column and match.match_end >= cursor_column then
            break
        end
    end

    if match.filename then
        if cursor_column > match.filename_end then
            vim.api.nvim_win_set_cursor(0, { position[1], match.filename_end })
        end

        local file_changed = pcall(vim.cmd, "norm! gF")

        if not file_changed and config.message_on_error then
            print("Failed to go to file")
        end

        if file_changed and match.line_number then
            pcall(vim.api.nvim_win_set_cursor, 0, { match.line_number, match.colulmn or 0 })
        end
    end
end

---@param opts? better-goto-file.Options
M.setup = function(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("keep", opts, default_config)

    vim.api.nvim_create_user_command("GotoFile", M.goto_file,
        { desc = "Goto file under cursor", force = false })
end

return M
