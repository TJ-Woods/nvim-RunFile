local M = {}

-- Default configuration
M.config = {
    terminal_size = 0.25,   -- % of current window height/width
    split = "split",        -- vsplit | split
    cleanup = false,        -- Delete built files after run
    auto_close = false,     -- Close terminal window on success
}

function M.setup(opts)
    if type(opts) ~= "table" then return end

    -- Validate types without overwriting defaults
    local function validate(key, expected_type)
        if opts[key] ~= nil and type(opts[key]) ~= expected_type then
            vim.notify("[RunFile] Invalid type for " .. key, vim.log.levels.WARN)
            opts[key] = nil -- Clear invalid value so it doesn't overwrite default
        end
    end

    validate("terminal_size", "number")
    validate("split", "string")
    validate("cleanup", "boolean")
    validate("auto_close", "boolean")

    -- Range check for size
    if opts.terminal_size and (opts.terminal_size <= 0 or opts.terminal_size >= 1) then
        opts.terminal_size = 0.25
    end

    -- Value check for split
    if opts.split and opts.split ~= "split" and opts.split ~= "vsplit" then
        opts.split = "split"
    end

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
        and math.floor(vim.api.nvim_win_get_width(main_win) * run_config.terminal_size)
        or math.floor(vim.api.nvim_win_get_height(main_win) * run_config.terminal_size)

    -- Create terminal split
    vim.cmd("belowright " .. size .. run_config.split .. " | enew")
    local term_buf = vim.api.nvim_get_current_buf()
    local term_win = vim.api.nvim_get_current_win()

    -- Ensure buffer is wiped when closed to save memory
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = term_buf })

    vim.fn.termopen(cmd, {
        on_exit = function(_, exit_code, _)
            -- schedule function to give time for UI to catch up
            vim.schedule(function()
                -- Auto-close logic: only close if command was successful (exit 0)
                if exit_code == 0 and run_config.auto_close then
                    if vim.api.nvim_win_is_valid(term_win) then
                        vim.api.nvim_win_close(term_win, true)
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
        end
    })

    vim.cmd("startinsert")
end

-- Parse flags for :RunFile command
local function parse_args(args_str)
    local overrides = {}
    -- Split string by spaces, handling potential quotes
    local args = vim.split(args_str or "", " ", { trimempty = true })

    local i = 1
    while i <= #args do
        local arg = args[i]
        local next_arg = args[i+1]

        if arg == "--terminal-size" then
            if next_arg and not next_arg:match("^%-%-") then
                local num = tonumber(next_arg:gsub('"', ''):gsub("'", ""))   -- Strip quotes
                if num and (num <= 0 and num <= 1) then
                    overrides.terminal_size = num
                end
                i = i + 1   -- Used next word, skip to next
            else
                vim.notify("[RunFile] Missing size for --terminal-size", vim.log.levels.ERROR)
            end
        elseif arg == "--split" then
            if next_arg and not next_arg:match("^%-%-") then
                local str = next_arg:gsub('"', ''):gsub("'", "") -- Strip quotes
                if str == "split" or str == "vsplit" then
                    overrides.split = str
                end
                i = i + 1   -- Used next word, skip to next
            else
                overrides.split = "split" -- Default alias for --split
            end
        elseif arg == "--cleanup" then
            overrides.cleanup = true
        elseif arg == "--no-cleanup" then
            overrides.cleanup = false
        elseif arg == "--auto-close" then
            overrides.auto_close = true
        elseif arg == "--no-auto-close" then
            overrides.auto_close = false
        end
        i = i + 1
    end
    return overrides
end

-- RunFile Command
function M.run_file(opts)
    -- Get file name
    local file_name = vim.api.nvim_buf_get_name(0)
    if file_name == "" then return end
    vim.cmd.write()

    -- Check for flags
    local run_config = vim.deepcopy(M.config)
    if opts and opts.args and opts.args ~= "" then
        local overrides = parse_args(opts.args)
        run_config = vim.tbl_deep_extend("force", run_config, overrides)
    end

    -- Set variables
    local os_name = get_os()
    local ext = vim.fn.fnamemodify(file_name, ":e")
    local exe = get_exe_path(file_name)
    local cmd = ""

    -- Language-specific command generation
    if ext == "py" then
        local source = find_extra_file(file_name, "source")
        local py_bin = (os_name == "Windows_NT") and "python" or "python3"
        cmd = source and ('"' .. source .. '"') or (py_bin .. ' "' .. file_name .. '"')

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
