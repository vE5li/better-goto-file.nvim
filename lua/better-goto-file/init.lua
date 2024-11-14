local M = {}
local default_config = {
    file_pattern = "[a-zA-Z0-9_/~.%-]+",
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

    ---@class better-goto-file.Match
    ---@field filename string Filename under the cursor
    ---@field filename_end integer Last column of filename
    ---@field match_start integer First column of the match
    ---@field match_end integer Last column of the match
    ---@field line_number? integer Optional line number after the filename
    ---@field column? integer Optional column after the filename

    ---@type better-goto-file.Match|nil
    local match

    ---@type integer|nil, integer|nil
    local match_start, match_end = 1, 0

    while true do
        match_start, match_end = string.find(line, config.file_pattern, match_end + 1)

        if not match_start or not match_end or match_start > cursor_column then
            match = nil

            if config.message_on_error then
                print("No filename under cursor")
            end

            break
        end

        match = {
            filename = line:sub(match_start, match_end),
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
        if match_next(config.line_pattern) then
            local line_number = match_next(config.number_pattern)

            if line_number then
                match.match_end = match_end
                match.line_number = tonumber(line_number)

                if match_next(config.column_pattern) then
                    local column = match_next(config.number_pattern)

                    if column then
                        match.match_end = match_end
                        match.column = tonumber(column)
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

        local file_changed = pcall(vim.cmd, "norm! gF")

        if not file_changed and config.message_on_error then
            print("Failed to go to file")
        end

        if file_changed and match.line_number then
            pcall(vim.api.nvim_win_set_cursor, 0, { match.line_number, match.column or 0 })
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
