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

# Notes
* This plugin was developed on and for Linux systems. While Windows and Mac _should_ be supported, they have not been tested.

