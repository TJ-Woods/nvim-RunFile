local M = {}

-- Default configuration
M.config = {
    terminal_size = 0.25,   -- % of current buffer that the terminal window will take up
    split = "split",        -- vsplit| or split--
    cleanup = false,        -- Whether built files are cleaned up (deleted) after running
    auto_close = false,     -- Whether the terminal buffer will close upon end program
}

function M.setup(opts)
    -- Check if opts is a table
    if opts and type(opts) ~= "table" then
        vim.notify("[RunFile] setup() expects a table", vim.log.levels.ERROR)
        return
    end

    -- Validate terminal_size
    if opts and opts.terminal_size then
        local val = opts.terminal_size
        if type(val) ~= "number" or val <= 0 or val >= 1 then
            vim.notify(
                "[RunFile] terminal_size must be a number between 0 and 1 (exclusive).",
                vim.log.levels.ERROR
            )
            -- Reset invalid value to default so it doesn't break merge
            opts.terminal_size = 0.25
        end
    end
    if opts and opts.split then
        local val = opts.split
        if type(val) ~= "string" or (val ~= "split" and val ~= "vsplit") then
            vim.notify(
                "[RunFile] split must be either 'split' or 'vsplit'.",
                vim.log.levels.ERROR
            )
            -- Reset invalid value to default so it doesn't break merge
            opts.split = "split"
        end
    end
    if opts and opts.cleanup ~= nil then
        local val = opts.cleanup
        if type(val) ~= "boolean" then
            vim.notify(
                "[RunFile] cleanup must be a boolean value.",
                vim.log.levels.ERROR
            )
            -- Reset invalid value to default so it doesn't break merge
            opts.cleanup = false
        end
    end

    -- Safely merge valid options
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function get_os()
    return vim.uv.os_uname().sysname
end

local function run_cmd(cmd, on_finish)
    local cur_win = vim.api.nvim_get_current_win()

    -- Calculate size based on split direction
    local size = (M.config.split == "vsplit") 
        and math.floor(vim.api.nvim_win_get_width(cur_win) * M.config.terminal_size)
        or math.floor(vim.api.nvim_win_get_height(cur_win) * M.config.terminal_size)

    -- Create split
    vim.cmd("belowright " .. size .. M.config.split .. " | enew")
    local buf = vim.api.nvim_get_current_buf()

    -- Set the buffer to 'wipe' so it deletes itself when the window closes
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

    -- Start the job in the terminal buffer
    vim.fn.termopen(cmd, {
        on_exit = function(_, exit_code, _)
            -- Close the window associated with the buffer
            if exit_code == 0 and M.config.auto_close and buf_exists then
                if vim.api.nvim_buf_is_valid(buf) then -- check user hasn't deleted buffer
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
            end
            if on_finish and buf_exists then
                on_finish(exit_code)
            end
        end
    })

    -- Auto-scroll to bottom
    vim.cmd("startinsert")
end

local function get_shell_ext()
    local os = get_os()
    if os == "Linux" or os == "Darwin" then return ".sh" end
    return ".bat" -- Default fallback
end

local function search_dir(dir, target)
    local path = dir .. target
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil
end

local function find_extra_file(file_name, target_name)
    local dir = vim.fn.fnamemodify(file_name, ":p:h") .. "/"
    local target = target_name .. get_shell_ext()
    if search_dir(dir, target) then
        return dir .. target
    end
    return nil
end

local function get_exe_path(file_path)
    local os_name = get_os()
    local ext = vim.fn.fnamemodify(file_path, ":e")
    local base_path = vim.fn.fnamemodify(file_path, ":p:r")

    -- Define which extensions produce an executable
    if ext == "c" or ext == "cpp" then
        if os_name == "Windows_NT" then
            return base_path .. ".exe"
        else
            return base_path
        end
    end

    return nil -- Not a compiled file type
end

function M.cleanup(exe)
    if not exe or exe == "" then return end
    -- Check if file exists before trying to delete
    if vim.uv.fs_stat(exe) then
        local success, err = vim.uv.fs_unlink(exe)
        if success then
            vim.notify("Cleaned up: " .. vim.fn.fnamemodify(exe, ":t"), vim.log.levels.INFO)
        else
            vim.notify("Cleanup failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
    end
end

function M.run_file()
    local file_name = vim.api.nvim_buf_get_name(0)
    if file_name == "" then return end
    vim.cmd.write()

    local os_name = get_os()
    local ext = vim.fn.expand("%:e")

    local cmd = ""
    local exe = get_exe_path(file_name)

    -- Logic Mapping
    if ext == "py" then
        local source = find_extra_file(file_name, "source")
        cmd = source and ('"' .. source .. '"') or ((os_name == "Windows_NT") and "python" or "python3") .. ' "' .. file_name .. '"'

    elseif ext == "js" then
        cmd = 'node "' .. file_name .. '"'

    elseif ext == "c" or ext == "cpp" then
        local compiler = (ext == "c") and "gcc" or "g++"
        local build_file = find_extra_file(file_name, "build")

        if build_file then
            cmd = '"' .. build_file .. '"'
        else
            -- Only runs the file if compilation is successful
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

    -- Execute with a callback for cleanup
    run_cmd(cmd, function(exit_code)
        if M.config.cleanup and exe and exit_code == 0 then
            M.cleanup(exe)
        end
    end)
end

return M
