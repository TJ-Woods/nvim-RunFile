-- Prevent loading twice
if vim.g.loaded_my_runner then return end
vim.g.loaded_my_runner = 1

-- Command for RunFile
vim.api.nvim_create_user_command("RunFile", function()
    require("RunFile").run_file()
end, {})

-- Command for Cleanup
vim.api.nvim_create_user_command("RunCleanup", function()
    require("RunFile").cleanup()
end, {})

-- Default Keymap for RunFile
vim.keymap.set("n", "<A-r>", ":RunFile<CR>", { silent = true, desc = "Run current file" })
