# nvim-RunFile
Neovim plugin that runs files in the terminal

----------
# Supported File Types
- [x] Python (.py) \[option to use source file]
- [x] Lua (.lua)
- [x] C (.c) \[option to use build file]
- [x] C++ (.cpp) \[option to use build file]
- [x] Powershell (.ps1)
- [x] Batch (.bat)
- [x] Shell (.sh)
- [x] Odin (.odin) \[option to use build file]
- [ ] JavaScript (.js) \[limited]

More to come!

----------
# Current Issues
* Limited language availability
* Performing a keyboard interrupt in true_terminal will also terminate the terminal and subsequently close the buffer

----------
# Setup
Set up this plugin using:

``` Lua
require("RunFile").setup()
```

## Options
Options are to be placed inside the `()` when calling .setup().

Options include the following defaults:
``` Lua
{-- These are the default
    terminal_size = 25,     -- % of current buffer the terminal window will take up
    split = "split",        -- "split" or "vslpit" or "float"
    cleanup = false,        -- Delete built executable files after running
    auto_close = false,     -- Close the terminal buffer if exit code is 0
    true_terminal = true,   -- Use a terminal rather than an output console
    run = true,             -- Run the compiled file (Compiled languages only)
    single_file = false,    -- Compile package from a single file (Odin only)
    force_quick_run = false, -- (EXPERIMENTAL) Force quick-run rather than running a build file (built languages only)
}
```
Additionally, you can add filetype-specific config options to override the global defaults for certain file types.
``` Lua
{-- Example only
    -- Global
    auto_close = false,
    true_terminal = false,
    -- Use the file extension name for configuring options ( e.g. py, cpp, js )
    py = {  -- Affects all .py files
        auto_close = true,
        true_terminal = true,
        terminal_size = 30,
        split = "float"
    },
}
```
This allows for global defaults with filetype-specific config. Command flags will override these.

All defaults are configurable.
Feel free to suggest things you would like to customise!

## Dependancies
* Requires only the language compilers/binaries for the languages you are running

----------
# Usage
The current file can be run using the command `:RunFile` with flags to overwrite defaults or custom-set preferences:
``` Cmd
--terminal-size <size>  Specifies the terminal size. <size> must be between 0 and 100 exclusive
--split <split>         Specifies the split direction. <split> must be one of "split", "vsplit", "float". Defaults to `split`
--vsplit                Alias for `--split vsplit`
--float                 Alias for `--split float`
--cleanup <bool>        Enables cleanup (deletes built files). Defaults to `true`
--no-cleanup            Alias for `--cleanup false`
--auto-close <bool>     Enables auto_close (terminal buffer closes upon successful execution). Defaults to `true`
--no-auto-close         Alias for `--auto-close false`
--true-terminal <bool>  Enables true_terminal. Defaults to `true`
--false-terminal        Alias for `--true-terminal false`
--run <bool>            Runs the executable file after compilation. Defaults to `true`
--no-run                Alias for `--run false`
--build                 Alias for `--run false`
--force-quick-run       (EXPERIMENTAL) forces quick run, bypassing build file
```

The values accepted for <bool|true> = "true", "yes", "1"
The values accepted for <bool|false> = "false", "no", "0"

----------
# Notes
* This plugin was developed on and for Linux systems. While Windows and Mac _should_ be supported, they have not been tested.

## More to come!
Here are some things to look forward to:
* More languages to the supported language list
* Makefile support
* Use of compiler flags for compiled languages
