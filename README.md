# nvim-RunFile
Neovim plugin that runs files in the terminal

----------
# Supported File Types
- [x] Python (.py) \[option to use source file]
- [x] C (.c) \[option to use build file]
- [x] C++ (.cpp) \[option to use build file]
- [x] Powershell (.ps1)
- [x] Batch (.bat)
- [x] Shell (.sh)
- [/] JavaScript (.js) \[limited]

More to come!

----------
# Current Issues
* Limited language availability
* Keyboard input (including keyboard interrupt) not compatible with `:RunFile --false-terminal`
* No testing for if conflicting flags are given (e.g. `:RunFile --true-terminal --false-terminal`

----------
# Setup
Set up this plugin using:

``` Lua
require("RunFile").setup()
```

## Options
Options are to be placed inside the "{}" when calling .setup().

Options include the following defaults:
``` Lua
{-- These are the default
    terminal_size = 25,     -- % of current buffer the terminal window will take up
    split = "split",        -- "split" or "vslpit"
    cleanup = false,        -- Delete built executable files after running
    auto_close = false,     -- Close the terminal buffer if exit code is 0
    true_terminal = true,   -- Use a terminal rather than an output console
}
```
Additionally, you can add filetype-specific config options.
``` Lua
{-- Example only
    -- Global
    auto_close = false,
    true_terminal = false,
    -- Use the file extension name for configuring options ( e.g. py, c, js )
    py = {  -- Affects all .py files
        auto_close = true,
        true_terminal = true,
        terminal_size = 30,
    },
}
```
This allows for global defaults with filetype-specific config. Command flags will override these.

All defaults are configurable.
Feel free to add suggestions for things you would like to customise!

## Dependancies
* None!

----------
# Usage
The current file can be run using the command `:RunFile` with flags to overwrite defaults or custom-set preferences:
``` Cmd
--terminal-size <size>  Specifies the terminal size. <size> must be between 0 and 100 exclusive
--split <split>         Specifies the split direction. <split> must be one of "split", "vsplit". Defaults to "split" if not given
--vsplit                Specifies the split direction. Alias for `--split vsplit`
--cleanup               Enables cleanup (deletes built files)
--no-cleanup            Disables cleanup (wont delete built files)
--auto-close            Enables auto_close (terminal buffer closes upon successful execution)
--no-auto-close         Disables auto_close (terminal buffer remains open upon successful execution)
--true-terminal         Enables true_terminal
--false-terminal        Disables true_terminal
```

The default keybind for this command is \<M-r\>

----------
# Notes
* This plugin was developed on and for Linux systems. While Windows and Mac _should_ be supported, they have not been tested.

## More to come!
Here are some things to look forward to:
* Plans to add more languages to the supported language list
* More control on compiled languages building vs running
* floating terminal option
