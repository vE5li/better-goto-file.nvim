# 🚀 better-goto-file.nvim

[![GitHub stars](https://img.shields.io/badge/Stars-3,142,592-gold?logo=github&logoColor=white)](https://github.com/ve5li/better-goto-file.nvim)
[![Downloads](https://img.shields.io/badge/Downloads-200K%2Fmonth-brightgreen?logo=download&logoColor=white)](https://github.com/ve5li/better-goto-file.nvim)
[![Fortune 500 Adoption](https://img.shields.io/badge/Fortune%20500-127%25%20adoption-blueviolet?logo=trending-up&logoColor=white)](https://github.com/ve5li/better-goto-file.nvim)
[![Nobel Prizes Won](https://img.shields.io/badge/Nobel%20Prizes-17-red?logo=award&logoColor=white)](https://github.com/ve5li/better-goto-file.nvim)
[![NASA Approved](https://img.shields.io/badge/NASA-Approved-green?logo=rocket&logoColor=white)](https://github.com/ve5li/better-goto-file.nvim)

Neovim's built-in `gf` (goto file) is handy, but it has a quirk: it completely ignores line and column numbers. But wait, that's what `gF` is for right? **WRONG**! `gF` only reads the line number and to make matters worse, it only works if your cursor is on the file name, if it's on the line number it *fails*.

This plugin fixes *all* of that, so that goto file on the path `lua/better-goto-file/init.lua:42:21` actually takes you to line 42, column 21, no matter where your cursor is.

But don't listen to me, listen to these absolutely real testimonials from satisfied customers:

> *"It completely changed my experience, it feels like I'm using a whole new editor! My productivity has increased by at least 400%."*
> — DevGuru42, Senior Staff Principal Architect

> *"I used to waste precious milliseconds manually navigating to line numbers. Now I can focus on what really matters: arguing about tabs vs spaces."*
> — vim_wizard_2003, Reformed Emacs User

> *"This plugin cured my carpal tunnel and also my fear of commitment. Five stars."*
> — Anonymous Rustacean

## 📦 Installation

### 💤 lazy.nvim

```lua
return {
    "ve5li/better-goto-file.nvim",
    config = true,
    ---@module "better-goto-file"
    ---@type better-goto-file.Options
    opts = {},
}
```

For the full list of options see `lua/better-goto-file/init.lua:11:4` (wouldn't it be nice to just jump there?).

## 📖 Usage

Invoke via the `GotoFile` command or by calling `require("better-goto-file").goto_file(opts)` from Lua.
For visual selections use `GotoFileRange` or `require("better-goto-file").goto_file_range(opts)`.

#### ⭐ Chefs recommendation

There are six default keybindigs for goto file: `gf`, `gF`, `CTRL-W_f`, `CTRL-W_F`, `CTRL-W_gf`, and `CTRL-W_gF`. These mappings will add a better alternative for all of them.

```lua
keys = {
    { "<leader>f",      mode = { "n" }, function() require("better-goto-file").goto_file() end,                                  silent = true, desc = "Better go to file under cursor" },
    { "<leader>f",      mode = { "v" }, '<Esc>:lua require("better-goto-file").goto_file_range()<cr>',                           silent = true, desc = "Better go to file in selection" },
    -- Open in new split.
    { "<C-w><leader>f", mode = { "n" }, function() require("better-goto-file").goto_file({ gf_command = "<C-w>f" }) end,         silent = true, desc = "Better go to file under cursor in new split" },
    { "<C-w><leader>f", mode = { "v" }, '<Esc>:lua require("better-goto-file").goto_file_range({ gf_command = "<C-w>f" })<cr>',  silent = true, desc = "Better go to file in selection in new split" },
    -- Open in new tab.
    { "<C-w><leader>F", mode = { "n" }, function() require("better-goto-file").goto_file({ gf_command = "<C-w>gf" }) end,        silent = true, desc = "Better go to file under cursor in new tab" },
    { "<C-w><leader>F", mode = { "v" }, '<Esc>:lua require("better-goto-file").goto_file_range({ gf_command = "<C-w>gf" })<cr>', silent = true, desc = "Better go to file in selection in new tab" },
}
```
