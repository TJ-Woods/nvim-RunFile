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
* Keyboard interrupts not compatible with `:RunFile --false-terminal`

----------
# Setup
Set up this plugin using:

``` Lua
require("RunFile").setup({})
```

## Options
Options are to be placed inside the "{}" when calling .setup().

Options include the following defaults:
``` Lua
{
    terminal_size = 25,     -- % of current buffer the terminal window will take up
    split = "split",        -- "split" or "vslpit"
    cleanup = false,        -- Delete built executable files after running
    auto_close = false,     -- Close the terminal buffer if exit code is 0
    true_terminal = true,   -- Use a terminal rather than an output console
}
```
All defaults are configurable.
Feel free to add suggestions for things you would like to customise!

## Dependancies
* None!

----------
# Usage
The current file can be run using the command `:RunFile` with arguments to overwrite defaults or custom-set preferences:
```command
--terminal-size <size>  Specifies the terminal size. <size> must be between 0 and 100 exclusive
--split <split>         Specifies the split direction. <split> must be one of "split", "vsplit". Defaults to "split" if not given
--cleanup               Invokes cleanup (deletes built files)
--no-cleanup            Disables cleanup (won\'t delete built files)
--auto-close            Enables auto_close (terminal buffer closes upon successful execution)
--no-auto-close         Disables auto_close (terminal buffer remains open upon successful execution)
--true-terminal         Enables true_terminal
--false-terminal        Disables true_terminal
```

The default keybind for this command is \<A-r\>

----------
# Notes
* This plugin was developed on and for Linux systems. While Windows and Mac _should_ be supported, they have not been tested.

## More to come!
Here are some things to look forward to:
* Plans to add more languages to the supported language list
* Plans to make file-type specific config settings
