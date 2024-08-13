-- This is just a shortcut that allows us to use `o` as an alias for `vim.opt`
-- local o = vim.opt

-- o.comatible = false
-- o.number = true
-- o.cmdheight = 2

vim.api.nvim_create_augroup("AutoFormat", {})

vim.api.nvim_create_autocmd(
    "BufWritePost",
    {
        pattern = "*.py",
        group = "AutoFormat",
        callback = function()
            vim.cmd("silent !black --quiet %")            
            vim.cmd("edit")
        end,
    }
)
