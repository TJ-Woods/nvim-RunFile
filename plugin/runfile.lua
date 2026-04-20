-- Prevent loading twice
if vim.g.loaded_my_runner then return end
vim.g.loaded_my_runner = 1

-- Create the User Command
vim.api.nvim_create_user_command("RunFile", function()
    require("RunFile").run_file()
end, {})

-- Optional: Default Keymap (e.g., <leader>r)
vim.keymap.set("n", "<A-r>", ":RunFile<CR>", { silent = true, desc = "Run current file" })
