M = require("RunFile")
-- Command for RunFile
vim.api.nvim_create_user_command("RunFile", function(opts)
    M.run_file(opts)
end, {
    nargs = "*",
    complete = function(arg_lead, cmd_line)
        local options = { "--terminal-size", "--split", "--vsplit", "--cleanup", "--no-cleanup", "--auto-close", "--no-auto-close", "--true-terminal", "--false-terminal" }

        -- Define pairs of flags that cannot exist together
        local conflicts = {
            ["--cleanup"] = "--no-cleanup",
            ["--no-cleanup"] = "--cleanup",
            ["--auto-close"] = "--no-auto-close",
            ["--no-auto-close"] = "--auto-close",
            ["--split"] = "--vsplit",
            ["--vsplit"] = "--split",
            ["--true-terminal"] = "--false-terminal",
            ["--false-terminal"] = "--true-terminal",
        }

        local ft = M.get_filetype()
        if ft == "odin" then
            table.insert(options, "--file")  -- Single-file package for Odin language
            table.insert(options, "--run")    -- Allow run
            table.insert(options, "--force-quick-run") -- Force quick-run
        elseif ft == "c" or ft == "cpp" then
            table.insert(options, "--run")    -- Allow run
            table.insert(options, "--force-quick-run") -- Force quick-run
        end

        if M.t_has(options, "--run") then
            table.insert(options, "--no-run")  -- Alias for --run false
            table.insert(options, "--build")   -- Alias for --run false

            conflicts["--run"] = "--no-run"
            conflicts["--run"] = "--build"
            conflicts["--no-run"] = "--run"
            conflicts["--no-run"] = "--build"
            conflicts["--build"] = "--run"
            conflicts["--build"] = "--no-run"
        end

        -- Split the current command line by spaces to see what's already typed
        local current_args = vim.split(cmd_line or "", "%s+", { trimempty = true })

        -- Track which flags we need to exclude
        local excluded = {}
        for _, arg in ipairs(current_args) do
            -- If the user typed a flag, exclude it from appearing again
            excluded[arg] = true
            -- If that flag has a known conflict, exclude the conflicting twin too
            if conflicts[arg] then
                excluded[conflicts[arg]] = true
            end
        end

        -- Filter the options list based on both the typed prefix AND our exclusions
        return vim.tbl_filter(function(item)
            local matches_prefix = item:find(arg_lead, 1, true) == 1
            local is_not_excluded = not excluded[item]
            return matches_prefix and is_not_excluded
        end, options)
    end
})
