local io = require("io")

local function unsupported_os()
    print("Unsupported OS '" .. os_name .. "'")
end

local function run_cmd(cmd, omit_insertion)
	local inpt = "i"
	if omit_insertion then
		inpt = ""
	end
	local command = vim.api.nvim_replace_termcodes(inpt .. cmd .. "<CR>", true, false, true)
	vim.api.nvim_feedkeys(command, "t", false)
end

local function get_os()
	local os_name = vim.loop.os_uname().sysname
	return os_name
end

local function get_call_func(os_name)
	local call = ""
	if os_name == "Linux" then
		call = ""
	else
        unsupported_os()
	end
	return call
end

local function get_exec_file_ext(os_name)
	local exec_file_ext = ""
	if os_name == "Linux" then
		exec_file_ext = ""
	else
        unsupported_os()
	end
	return exec_file_ext
end

local function get_shell_ext(os_name)
	local shell_ext = ""
	if os_name == "Linux" then
		shell_ext = ".sh"
	else
        unsupported_os()
	end
	return shell_ext
end

local function has_suffix(str, substr)
	local len = string.len(substr)
	local contains = string.sub(str, -len, -1) == substr
	return contains
end

local function search_dir(dir, target)
	local os_name = get_os()
	local found = false
	if os_name == "Linux" then
		for file in io.popen("ls -pa " .. dir .. " | grep -v /"):lines() do
			if target == file then
				found = true
				break
			end
		end
	else
        unsupported_os()
	end
	return found
end

local function find_build_file(file_name)
	local os_name = get_os()
	local shell_ext = get_shell_ext(os_name)

	local dir = string.sub(file_name, 0, -vim.fn.expand("%:t"):len() - 1)
	local build_file = "build" .. shell_ext
	if search_dir(dir, build_file) then
		return dir .. build_file
	else
		return nil
	end
end

local function find_source_file(file_name)
	local shell_ext = get_shell_ext(get_os())
	local dir = string.sub(file_name, 0, -vim.fn.expand("%:t"):len() - 1)
	local source_file = "source" .. shell_ext
	if search_dir(dir, source_file) then
		return dir .. source_file
	else
		return nil
	end
end

function RunFile()
	local file_name = vim.api.nvim_buf_get_name(0)
	vim.cmd.write(file_name)

	local os_name = get_os()
    local call = get_call_func(os_name)
	local exec_file_ext = get_exec_file_ext(os_name)

	if has_suffix(file_name, ".py") then
		local source_file = find_source_file(file_name) -- for build with venv
		if source_file then
			run_cmd(call .. '"' .. source_file .. '"', false)
		else
			if os_name == "Linux" then
				run_cmd('python3 "' .. file_name .. '"', false)
			end
		end
	elseif has_suffix(file_name, ".js") then
		run_cmd('node "' .. file_name .. '"', false)
	elseif has_suffix(file_name, ".c") then
		local name = string.sub(vim.api.nvim_buf_get_name(0), 0, -3) .. exec_file_ext
		local build_file = find_build_file(file_name)
		if build_file ~= nil then
			run_cmd(call .. '"' .. build_file .. '"', false) -- <call> has a space already
		else
			run_cmd('gcc "' .. file_name .. '" -o "' .. name .. '"', false)
			if "[no-error-during-build]" then -- TODO: detect error in build
				run_cmd('"' .. name .. '"', true)
			end
		end
	elseif has_suffix(file_name, ".cpp") then
		local name = string.sub(vim.api.nvim_buf_get_name(0), 0, -5) .. exec_file_ext
		local build_file = find_build_file(file_name)
		if build_file ~= nil then
			run_cmd(call .. '"' .. build_file .. '"', false)
		else
			run_cmd('g++ "' .. file_name .. '" -o "' .. name .. '"', false)
			if "[no-error-during-build]" then -- TODO: detect error in build
				run_cmd('"' .. name .. '"', false)
			end
		end
	elseif has_suffix(file_name, ".ps1") then
		run_cmd('powershell "' .. file_name .. '"', false)
	elseif has_suffix(file_name, ".bat") then
		run_cmd(call .. '"' .. file_name .. '"', false)
	elseif has_suffix(file_name, ".sh") then
		run_cmd(call .. '"' .. file_name .. '"', false)
	else
		local name = vim.fn.expand("%:t")
		vim.print([[
Cannot run this file ']] .. name .. [['; it is not supported by this plugin. --T
Supported file types include:
    > Python (.py) [option to use source file]
    > JavaScript (.js)
    > C (.c) [option to use build file]
    > C++ (.cpp) [option to use build file]
    > Powershell (.ps1)
    > Batch (.bat)
    > Shell (.sh)
        ]])
		return 0
	end

	local term_height = 0.25 -- Percentage of window height
	local curr_win_height = vim.api.nvim_win_get_height(0)
	local dis_height = math.floor(curr_win_height * term_height)
	vim.cmd(":below " .. dis_height .. "split | term")
end
