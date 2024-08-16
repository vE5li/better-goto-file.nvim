local M = {}

local config = {
    regex = "([a-zA-Z_/]+)(:[0-9]+)(:[0-9]+)",
}

M.setup = function( --[[ config ]])
    vim.api.nvim_create_user_command("GotoFile", function()
            local word = vim.fn.expand("<cWORD>")

            for file, line, column in string.gmatch(word, config.regex) do

                local stripped_line = line:sub(2)
                local stripped_column = column:sub(2)

                local adjusted_line = tonumber(stripped_line)
                local adjusted_column = tonumber(stripped_column) - 1

                vim.cmd("norm! gF")
                vim.api.nvim_win_set_cursor(0, { adjusted_line, adjusted_column })

                return
            end
        end,
        { desc = "Goto file under cursor", force = false })
end

return M
