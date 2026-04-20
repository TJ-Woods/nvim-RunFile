local M = {}

-- Default configuration
M.config = {
    terminal_size = 0.25,   -- % of current buffer that the terminal window will take up
    split = "split",        -- vsplit| or split--
    cleanup = false,        -- Whether built files are cleaned up (deleted) after running
}

function M.setup(opts)
    -- Check if opts is a table
    if opts and type(opts) ~= "table" then
        vim.notify("[RunFile] setup() expects a table", vim.log.levels.ERROR)
        return
    end

    -- Validate terminal_height
    if opts and opts.terminal_height then
        local val = opts.terminal_height
        if type(val) ~= "number" or val <= 0 or val >= 1 then
            vim.notify(
                "[RunFile] terminal_height must be a number between 0 and 1 (exclusive).",
                vim.log.levels.ERROR
            )
            -- Reset invalid value to default so it doesn't break merge
            opts.terminal_height = 0.25
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
    return vim.loop.os_uname().sysname
end

local function run_cmd(cmd)
    local command = vim.api.nvim_replace_termcodes("i" .. cmd .. "<CR>", true, false, true)
    vim.api.nvim_feedkeys(command, "t", false)
end

local function get_shell_ext()
    local os = get_os()
    if os == "Linux" or os == "Darwin" then return ".sh" end
    return ".bat" -- Default fallback
end

local function search_dir(dir, target)
    local path = dir .. target
    local stat = vim.loop.fs_stat(path)
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

function M.cleanup()
    local exe = get_exe_path()
    -- Check if file exists before trying to delete
    if vim.loop.fs_stat(exe) then
        local success, err = vim.loop.fs_unlink(exe)
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
    local base_path = vim.fn.expand("%:p:r")

    -- Logic Mapping
    if ext == "py" then
        local source = find_extra_file(file_name, "source")
        run_cmd(source and ('"' .. source .. '"') or ((os_name == "Windows_NT") and "python" or "python3" .. ' "' .. file_name .. '"'))

    elseif ext == "js" then
        run_cmd('node "' .. file_name .. '"')

    elseif ext == "c" or ext == "cpp" then
        local compiler = (ext == "c") and "gcc" or "g++"
        local build_file = find_extra_file(file_name, "build")

        if build_file then
            run_cmd('"' .. build_file .. '"')
        else
            local exe = base_path .. (os_name == "Windows_NT" and ".exe" or "")
            -- Only runs the file if compilation is successful
            run_cmd(compiler .. ' "' .. file_name .. '" -o "' .. exe .. '" && "' .. exe .. '"')
            -- Clean up built executable file
            if M.config.cleanup then
                M.cleanup()
            end
        end

    elseif ext == "ps1" then
        run_cmd('powershell "' .. file_name .. '"')

    elseif vim.tbl_contains({"sh", "bat"}, ext) then
        run_cmd('"' .. file_name .. '"')

    else
        vim.notify("Unsupported file type: " .. ext, vim.log.levels.WARN)
        return
    end

    -- Terminal split
    local dis_size = math.floor(vim.api.nvim_win_get_height(0) * M.config.terminal_size)
    vim.cmd("belowright " .. dis_size .. " " .. M.config.split .. " | term")
end

return M
