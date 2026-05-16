-- Prevent loading twice
if vim.g.loaded_runfile then return end
vim.g.loaded_runfile = 1

-- Command for RunFile
vim.api.nvim_create_user_command("RunFile", function(opts)
    require("RunFile").run_file(opts)
end, {
    nargs = "*",
    complete = function(arg_lead)
        local options = {"--terminal-size", "--split", "--cleanup", "--no-cleanup", "--auto-close", "--no-auto-close", "--true-terminal", "--false-terminal"}
        -- Filter based on what the user has already typed
        return vim.tbl_filter(function(item)
            return item:find(arg_lead, 1, true)
        end, options)
    end
})

-- Default Keymap for RunFile
vim.keymap.set("n", "<A-r>", function() require("RunFile").run_file() end, { silent = true, desc = "Run current file" })
