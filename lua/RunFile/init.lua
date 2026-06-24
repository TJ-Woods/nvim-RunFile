local M = {}

-- Default configuration
M.config = {
    terminal_size = 25,     -- % of current window height/width
    split = "split",        -- vsplit | split
    cleanup = false,        -- Delete built files after run
    auto_close = false,     -- Close terminal window on success
    true_terminal = true,   -- Terminal vs output console after running
}

function M.setup(opts)
    if type(opts) ~= "table" then return end

    -- Reusable validation function for a configuration block
    local function validate_config_block(block)
        if type(block) ~= "table" then return end

        local valid_types = {
            terminal_size = "number",
            split = "string",
            cleanup = "boolean",
            auto_close = "boolean",
            true_terminal = "boolean",
        }

        for key, expected_type in pairs(valid_types) do
            if block[key] ~= nil then
                if type(block[key]) ~= expected_type then
                    vim.notify("[RunFile] Invalid type for " .. key, vim.log.levels.WARN)
                    block[key] = nil -- Clear invalid value
                end

                -- Specific range validations
                if key == "terminal_size" and block.terminal_size then
                    if block.terminal_size < 0 or block.terminal_size > 100 then
                        vim.notify("[RunFile] terminal_size must be between 0 and 100", vim.log.levels.WARN)
                        block.terminal_size = nil
                    end
                end

                if key == "split" and block.split then
                    if block.split ~= "split" and block.split ~= "vsplit" then
                        vim.notify("[RunFile] split must be 'split' or 'vsplit'", vim.log.levels.WARN)
                        block.split = nil
                    end
                end
            end
        end
    end

    -- Validate top-level global settings
    validate_config_block(opts)

    -- Validate nested filetype tables
    for _, val in pairs(opts) do
        if type(val) == "table" then
            validate_config_block(val)
        end
    end

    -- Safely merge everything into the master config
    M.config = vim.tbl_deep_extend("force", M.config, opts)
end

local function get_os()
    return vim.uv.os_uname().sysname
end

local function get_shell_ext()
    local os = get_os()
    if os == "Linux" or os == "Darwin" then return ".sh" end
    return ".bat"
end

-- Generates the path for compiled binaries (C/C++)
local function get_exe_path(file_path)
    local os_name = get_os()
    local ext = vim.fn.fnamemodify(file_path, ":e")
    local base_path = vim.fn.fnamemodify(file_path, ":p:r")

    if ext == "c" or ext == "cpp" then
        return (os_name == "Windows_NT") and (base_path .. ".exe") or base_path
    end
    return nil
end

local function search_dir(dir, target)
    local stat = vim.uv.fs_stat(dir .. target)
    return stat ~= nil
end

-- Looks for source.sh/bat or build.sh/bat in the same directory
local function find_extra_file(file_name, target_name)
    local dir = vim.fn.fnamemodify(file_name, ":p:h") .. "/"
    local target = target_name .. get_shell_ext()
    if search_dir(dir, target) then
        return dir .. target
    end
    return nil
end

-- Handles terminal split creation, command execution, and post-run cleanup
local function run_cmd(cmd, exe_to_clean, run_config)
    local main_win = vim.api.nvim_get_current_win()

    -- Calculate split size based on current window dimensions
    local size = (run_config.split == "vsplit")
        and math.floor(vim.api.nvim_win_get_width(main_win) * (run_config.terminal_size / 100))
        or math.floor(vim.api.nvim_win_get_height(main_win) * (run_config.terminal_size / 100))

    -- Create a clean split window
    vim.cmd("belowright " .. size .. run_config.split .. " | enew")
    local term_buf = vim.api.nvim_get_current_buf()
    local term_win = vim.api.nvim_get_current_win()

    -- Ensure buffer is wiped when closed to avoid memory leak
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = term_buf })

    if run_config.true_terminal then
        -- True interactive terminal
        local shell = vim.o.shell
        local is_windows = get_os() == "Windows NT"

        local full_cmd = is_windows 
            and { shell, "/k", cmd }
            or { shell, "-c", cmd .. "; " .. shell }

        vim.fn.jobstart(full_cmd, {
            term = true,
            on_exit = function(_, exit_code, _)
                vim.schedule(function()
                    if exit_code == 0 and run_config.cleanup and exe_to_clean then
                        vim.defer_fn(function()
                            if vim.uv.fs_stat(exe_to_clean) then
                                vim.uv.fs_unlink(exe_to_clean)
                                vim.notify("Cleaned up: " .. vim.fn.fnamemodify(exe_to_clean, ":t"))
                            end
                        end, 150)
                    end
                    if exit_code == 0 and run_config.auto_close then
                        if vim.api.nvim_win_is_valid(term_win) then
                            vim.api.nvim_win_close(term_win, true)
                        end
                    end
                end)
            end
        })

    else
        -- Output Console with Keyboard Input
        vim.fn.jobstart(cmd, {
            term = true,
            on_exit = function(_, exit_code, _)
                vim.schedule(function()
                    if exit_code == 0 and run_config.auto_close then
                        if vim.api.nvim_win_is_valid(term_win) then
                            vim.api.nvim_win_close(term_win, true)
                        end
                    else
                        if vim.api.nvim_buf_is_valid(term_buf) then
                            vim.cmd("stopinsert")

                            local close_keys = { "<CR>", "<Esc>", "<Space>", "q" }
                            local map_opts = { buffer = term_buf, silent = true, noremap = true }

                            local close_fn = function()
                                if vim.api.nvim_win_is_valid(term_win) then
                                    vim.api.nvim_win_close(term_win, true)
                                end
                            end

                            for _, key in ipairs(close_keys) do
                                vim.keymap.set("n", key, close_fn, map_opts)
                            end
                        end
                    end

                    if run_config.cleanup and exe_to_clean and exit_code == 0 then
                        vim.defer_fn(function()
                            if vim.uv.fs_stat(exe_to_clean) then
                                vim.uv.fs_unlink(exe_to_clean)
                                vim.notify("Cleaned up: " .. vim.fn.fnamemodify(exe_to_clean, ":t"))
                            end
                        end, 150)
                    end
                end)
            end,
        })
    end

    vim.cmd("startinsert")
end

-- Parse flags for :RunFile command
local function parse_args(args_str)
    local overrides = {}
    local args = vim.split(args_str or "", " ", { trimempty = true })

    local seen_flags = {}
    local conflict_detected = false

    -- User string values into explicit booleans
    local function to_bool(val)
        if not val then return nil end
        val = val:lower():gsub('"', ''):gsub("'", "") -- Clean quotes and casing
        if val == "true" or val == "yes" or val == "1" then
            return true
        elseif val == "false" or val == "no" or val == "0" then
            return false
        end
        return nil
    end

    local i = 1
    while i <= #args do
        local arg = args[i]

        if arg == "--terminal-size" then
            local next_arg = args[i+1]
            if next_arg and not next_arg:match("^%-%-") then
                local numstring = next_arg:gsub('"', ''):gsub("'", "")
                local num = tonumber(numstring)
                if num and num > 0 and num < 100 then
                    if seen_flags["size"] then conflict_detected = true end
                    overrides.terminal_size = num
                    seen_flags["size"] = true
                end
                i = i + 1
            end

        elseif arg == "--split" then
            local next_arg = args[i+1]
            if next_arg and not next_arg:match("^%-%-") then
                local val = next_arg:gsub('"', ''):gsub("'", "")
                if val == "split" or val == "vsplit" then
                    if seen_flags["split"] then conflict_detected = true end
                    overrides.split = val
                    seen_flags["split"] = true
                end
                i = i + 1
            else
                if seen_flags["split"] then conflict_detected = true end
                overrides.split = "split"
                seen_flags["split"] = true
            end

        elseif arg == "--cleanup" or arg == "--no-cleanup" then
            if seen_flags["cleanup"] then conflict_detected = true end

            local next_arg = args[i+1]
            local val = next_arg:gsub('"', ""):gsub("'", "")

            -- Check if the next word is an explicit truth value
            local truthy = nil
            if (val == "yes" or val == "1" or val == "true") then
                truthy = true
            elseif (val == "no" or val == "0" or val == "false") then
                truthy = false
            end

            if truthy ~= nil and not next_arg:match("^%-%-") then
                overrides.cleanup = truthy
                i = i + 1 -- Skip the next argument since we consumed it
            else
                overrides.cleanup = (arg == "--cleanup")
            end
            seen_flags["cleanup"] = true

        elseif arg == "--auto-close" or arg == "--no-auto-close" then
            if seen_flags["auto_close"] then conflict_detected = true end

            local next_arg = args[i+1]
            local val = next_arg:gsub('"', ""):gsub("'", "")
            local truthy = nil
            if (val == "yes" or val == "1" or val == "true") then
                truthy = true
            elseif (val == "no" or val == "0" or val == "false") then
                truthy = false
            end

            if truthy ~= nil and not next_arg:match("^%-%-") then
                overrides.auto_close = truthy
                i = i + 1
            else
                overrides.auto_close = (arg == "--auto-close")
            end
            seen_flags["auto_close"] = true

        elseif arg == "--true-terminal" or arg == "--false-terminal" then
            if seen_flags["true_terminal"] then conflict_detected = true end

            local next_arg = args[i+1]
            local val = next_arg:gsub('"', ""):gsub("'", "")
            local truthy = nil
            if (val == "yes" or val == "1" or val == "true") then
                truthy = true
            elseif (val == "no" or val == "0" or val == "false") then
                truthy = false
            end

            if truthy ~= nil and not next_arg:match("^%-%-") then
                overrides.true_terminal = truthy
                i = i + 1
            else
                overrides.true_terminal = (arg == "--true-terminal")
            end
            seen_flags["true_terminal"] = true
        end
        i = i + 1
    end

    if conflict_detected then
        vim.notify("[RunFile] Conflicting or duplicate flags detected. Using the last values provided.", vim.log.levels.WARN)
    end

    return overrides
end

-- RunFile Command
function M.run_file(opts)
    -- Get full path
    local file_name = vim.api.nvim_buf_get_name(0)
    if file_name == "" then return end
    vim.cmd.write() -- Save file

    local ext = vim.fn.fnamemodify(file_name, ":e")

    -- Config
    local run_config = vim.deepcopy(M.config)
    -- Filetype overrides
    if M.config[ext] and type(M.config[ext]) == "table" then
        run_config = vim.tbl_deep_extend("force", run_config, M.config[ext])
    end
    -- Flag overrides
    if opts and opts.args and opts.args ~= "" then
        local flag_overrides = parse_args(opts.args)
        run_config = vim.tbl_deep_extend("force", run_config, flag_overrides)
    end

    -- Set variables
    local os_name = get_os()
    local exe = get_exe_path(file_name)
    local cmd = ""

    -- Language-specific command generation
    if ext == "py" then
        local source = find_extra_file(file_name, "source")
        local py_bin = (os_name == "Windows_NT") and "python" or "python3"
        cmd = source and ('"' .. source .. '"') or (py_bin .. ' "' .. file_name .. '"')

    elseif ext == "lua" then
        cmd = 'lua "' .. file_name .. '"'

    elseif ext == "js" then
        cmd = 'node "' .. file_name .. '"'

    elseif ext == "c" or ext == "cpp" then
        local compiler = (ext == "c") and "gcc" or "g++"
        local build_file = find_extra_file(file_name, "build")
        if build_file then
            cmd = '"' .. build_file .. '"'
        else
            -- Chain compilation and execution; only runs if compilation succeeds
            cmd = compiler .. ' "' .. file_name .. '" -o "' .. exe .. '" && "' .. exe .. '"'
        end
        -- TODO: Update to allow explicit build only
        -- TODO: Update to allow compiler flags
    elseif ext == "odin" then
        cmd = 'odin run "' .. file_name .. '" -file'  -- Runs as a single-file package ONLY
        -- TODO: Update to allow for multi-file build and run
        -- using directory instead of file_name
        -- cmd = 'odin run "' .. file_path .. '"' -- Normal build + run

    elseif ext == "ps1" then
        cmd = 'powershell "' .. file_name .. '"'

    elseif vim.tbl_contains({"sh", "bat"}, ext) then
        cmd = '"' .. file_name .. '"'

    else
        vim.notify("Unsupported file type: " .. ext, vim.log.levels.WARN)
        return
    end

    -- Run command and handle post-run cleanup
    run_cmd(cmd, exe, run_config)
end

return M
