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
* Limited languages available

# Setup
This plugin requires 
''' lua
require("RunFile").setup({})
'''

# Options
Options are to be placed inside the "{}" when calling .setup().

Options include the following defaults:
* terminal_size = 0.25  -- % of current buffer the terminal window will take up
* split = "split"       -- "split" or "vslpit"
* cleanup = false       -- whether built files are cleaned up (deleteed) after running
