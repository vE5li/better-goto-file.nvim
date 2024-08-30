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

---Go to file, line, and column under the cursor
---@param opts? better-goto-file.Options
M.goto_file = function(opts)
    opts = opts or {}
    local config = vim.tbl_deep_extend("keep", opts, default_config)

    local position = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_buf_get_lines(
            0,
            position[1] - 1,
            position[1],
            false
        )
        [1]
    local cursor_column = position[2] + 1
    local information

    ---@type integer|nil, integer|nil
    local start_pos, end_pos = 1, 0

    while true do
        start_pos, end_pos = string.find(line, config.file_pattern, end_pos + 1)

        if not start_pos or start_pos > cursor_column then
            print("No filename under cursor")
            information = { filename = nil };
            break
        end

        information = {
            filename = line:sub(start_pos, end_pos),
            filename_end = end_pos - 1,
            match_start = start_pos,
            match_end = end_pos,
            line_number = nil,
            colulmn = nil,
        }

        local function try_pattern(pattern, init)
            local remaining_line = line:sub(init + 1)
            local match_start, match_end = string.find(remaining_line, pattern)

            if match_start == 1 then
                local value = remaining_line:sub(match_start, match_end)
                return value, init + match_end
            end
        end

        local separator, separator_end = try_pattern(config.line_pattern, end_pos)
        if separator then
            local line_number, line_number_end = try_pattern(config.number_pattern, separator_end)

            if line_number then
                information.match_end = line_number_end
                information.line_number = tonumber(line_number)

                separator, separator_end = try_pattern(config.column_pattern, line_number_end)
                if separator then
                    local column, column_end = try_pattern(config.number_pattern, separator_end)
                    if column then
                        information.match_end = column_end
                        information.colulmn = tonumber(column)
                    end
                end
            end
        end

        if information.match_start <= cursor_column and information.match_end >= cursor_column then
            break
        end
    end

    if information.filename then
        if cursor_column > information.filename_end then
            vim.api.nvim_win_set_cursor(0, { position[1], information.filename_end })
        end

        local file_changed = pcall(vim.cmd, "norm! gF")

        if not file_changed and config.message_on_error then
            print("Failed to go to file")
        end

        if file_changed and information.line_number then
            if information.colulmn then
                vim.api.nvim_win_set_cursor(0, { information.line_number, information.colulmn - 1 })
            else
                vim.api.nvim_win_set_cursor(0, { information.line_number, 0 })
            end
        end
    end
end

---@param opts? better-goto-file.Options
M.setup = function(opts)
    vim.api.nvim_create_user_command("GotoFile", function() M.goto_file(opts) end,
        { desc = "Goto file under cursor", force = false })
end

return M
