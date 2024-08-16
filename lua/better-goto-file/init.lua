local M = {}

local config = {
    file_pattern = "[a-zA-Z_/~.%-]+",
    number_pattern = "[0-9]+",
    line_pattern = ":",
    column_pattern = "[:]",
}

local function do_match(line, pattern, init)
    local remaining_line = line:sub(init + 1)

    local match_start, match_end = string.find(remaining_line, pattern)

    if match_start == 1 then
        local value = remaining_line:sub(match_start, match_end)
        return value, init + match_end
    end

    return nil, nil
end

M.setup = function( --[[ config ]])
    vim.api.nvim_create_user_command("GotoFile", function()
            local position = vim.api.nvim_win_get_cursor(0)
            local line = vim.api.nvim_buf_get_lines(
                    0,
                    position[1] - 1,
                    position[1],
                    false
                )
                [1]
            local cursor_column = position[2] + 1

            local information = {
                filename = nil,
                filename_end = nil,
                line_number = nil,
                colulmn = nil,
            }

            local start_pos, end_pos = 1, 0
            while true do
                start_pos, end_pos = string.find(line, config.file_pattern, end_pos + 1)

                if not start_pos then
                    P("no filename under cursor")
                    break
                end

                if start_pos <= cursor_column and end_pos >= cursor_column then
                    information.filename = line:sub(start_pos, end_pos)
                    information.filename_end = end_pos

                    local separator, separator_end = do_match(line, config.line_pattern, end_pos)
                    if separator then
                        local line_number, line_number_end = do_match(line, config.number_pattern, separator_end)
                        if line_number then
                            information.line_number = tonumber(line_number)

                            separator, separator_end = do_match(line, config.column_pattern, line_number_end)
                            if separator then
                                local column = do_match(line, config.number_pattern, separator_end)
                                if column then
                                    information.colulmn = tonumber(column)
                                end
                            end
                        end
                    end

                    break
                end
            end

            if information.filename then
                -- TODO: For when we can also match on the line number
                -- if cursor_column > information.filename_end then
                --     vim.api.nvim_win_set_cursor(0, { position[1], information.filename_end })
                -- end

                vim.cmd("norm! gF")

                if information.line_number then
                    if information.colulmn then
                        vim.api.nvim_win_set_cursor(0, { information.line_number, information.colulmn - 1 })
                    else
                        vim.api.nvim_win_set_cursor(0, { information.line_number, 0 })
                    end
                end
            end
        end,
        { desc = "Goto file under cursor", force = false })
end

return M
