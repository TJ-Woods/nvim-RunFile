local M = {}

-- Default configuration
M.config = {
    terminal_size = 0.25,   -- % of current window height/width
    split = "split",        -- vsplit | split
    cleanup = false,        -- Delete built files after run
    auto_close = false,     -- Close terminal window on success
}

function M.setup(opts)
    if opts and type(opts) ~= "table" then
        vim.notify("[RunFile] setup() expects a table", vim.log.levels.ERROR)
        return
    end
    if opts and type(opts.terminal_size) ~= "number" or opts.terminal_size <= 0 or opts.terminal_size >= 1 then
        vim.notify("[RunFile] terminal_size must be a number between 0 and 1 (exclusive)", vim.log.levels.ERROR)
        opts.terminal_size = 0.25   -- Reset to default
    end
    if opts and type(opts.split) ~= "string" or (opts.split ~= "split" and opts.split ~= "vsplit" and opts.split ~= "float") then
        vim.notify("[RunFile] split must be one of 'split', 'vsplit', or 'float'.", vim.log.levels.ERROR)
        opts.split = "split"    -- Reset to default
    end
    if opts and type(opts.cleanup) ~= "boolean" then
        vim.notify("[RunFile] cleanup must be a boolean value.", vim.log.levels.ERROR)
        opts.cleanup = false    -- Reset to default
    end
    if opts and type(opts.auto_close) ~= "boolean" then
        vim.notify("[RunFile] auto_close must be a boolean value.", vim.log.levels.ERROR)
        opts.auto_close = false     -- Reset to default
    end

    -- Safely merge valid options
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
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

-- Deletes the compiled executable
function M.cleanup(exe)
    if not exe or exe == "" then return end
    if vim.uv.fs_stat(exe) then
        local success, err = vim.uv.fs_unlink(exe)
        if success then
            vim.notify("Cleaned up: " .. vim.fn.fnamemodify(exe, ":t"), vim.log.levels.INFO)
        else
            vim.notify("Cleanup failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
    end
end

-- Handles terminal split creation and command execution
local function run_cmd(cmd, on_finish)
    local cur_win = vim.api.nvim_get_current_win()
    
    -- Calculate split size based on current window dimensions
    local size = (M.config.split == "vsplit") 
        and math.floor(vim.api.nvim_win_get_width(cur_win) * M.config.terminal_size)
        or math.floor(vim.api.nvim_win_get_height(cur_win) * M.config.terminal_size)

    -- Create terminal split
    vim.cmd("belowright " .. size .. M.config.split .. " | enew")
    local buf = vim.api.nvim_get_current_buf()

    -- Ensure buffer is wiped when closed to save memory
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

    vim.fn.termopen(cmd, {
        on_exit = function(_, exit_code, _)
            -- Defer execution slightly to allow UI to finish rendering terminal output
            vim.defer_fn(function()
                -- Auto-close logic: only close if command was successful (exit 0)
                if exit_code == 0 and M.config.auto_close then
                    local win = vim.fn.bufwinid(buf)
                    if win and win ~= -1 then
                        vim.api.nvim_win_close(win, true)
                    end
                end

                if on_finish then
                    on_finish(exit_code)
                end
            end, 150)
        end
    })

    vim.cmd("startinsert")
end

function M.run_file()
    local file_name = vim.api.nvim_buf_get_name(0)
    if file_name == "" then return end
    vim.cmd.write()

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
    run_cmd(cmd, function(exit_code)
        if M.config.cleanup and exe and exit_code == 0 then
            M.cleanup(exe)
        end
    end)
end

return M
