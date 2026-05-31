-- Command for RunFile
vim.api.nvim_create_user_command("RunFile", function(opts)
    require("RunFile").run_file(opts)
end, {
    nargs = "*",
    complete = function(arg_lead, cmd_line)
        local options = { "--terminal-size", "--split", "--vsplit", "--cleanup", "--no-cleanup", "--auto-close", "--no-auto-close" }

        -- Define pairs of flags that cannot exist together
        local conflicts = {
            ["--cleanup"] = "--no-cleanup",
            ["--no-cleanup"] = "--cleanup",
            ["--auto-close"] = "--no-auto-close",
            ["--no-auto-close"] = "--auto-close",
            ["--split"] = "--vsplit",
            ["--vsplit"] = "--split",
        }

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
