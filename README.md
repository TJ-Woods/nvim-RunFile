# nvim-RunFile
Neovim plugin that runs files in the terminal

# Supported File Types
*  Python (.py) [option to use source file]
*  JavaScript (.js)
*  C (.c) [option to use build file]
*  C++ (.cpp) [option to use build file]
*  Powershell (.ps1)
*  Batch (.bat)
*  Shell (.sh)

More to come!

# Current Issues
* Limited language availability

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
    terminal_size = 0.25,  -- % of current buffer the terminal window will take up
    split = "split",       -- "split" or "vslpit"
    cleanup = false,       -- Whether built files are cleaned up (deleteed) after running
    auto_close = false,    -- Whether the terminal buffer will close upon end program
}
```

## Dependancies
* None!

# Usage
The current file can be run using the command `:RunFile` with arguments to overwrite defaults or custom-set preferences:
```
--term-size <size>      Specifies the terminal size. <size> must be between 0 and 1 exclusive
--split <split>         Specifies the split direction. <split> must be one of "split", "vsplit". Defaults to "split" if not given
--cleanup               Invokes cleanup (deletes built files)
--no-cleanup            Disables cleanup (won't delete built files)
--auto-close            Enables auto_close (terminal buffer closes upon successful execution)
--no-auto-close         Disables auto_close (terminal buffer remains open upon successful execution)
```

The default keybind for this command is <A-r>

# Notes
* This plugin was developed on and for Linux systems. While Windows and Mac _should_ be supported, they have not been tested.
