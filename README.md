# Usage

Lazy:

```lua
local keys = {
    { "<leader>f", ":GotoFile<cr>", silent = true, desc = "Goto file" },
}

return {
    "ve5li/better-goto-file.nvim",
    config = true,
    keys = keys,
}
```
