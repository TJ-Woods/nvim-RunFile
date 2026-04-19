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
*  Currently, there is no way for the program to determine if a build error has occurred in languages like C or C++, and therefore runs the build, hits an error preventing the build, and runs the previous (if existing) executable file.
*  There are currently no configurable options
