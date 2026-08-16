-- Native (host) debugging: CodeLLDB and cppdbg/gdb launches. These are
-- always available as defaults, regardless of what a project registers.

local util = require("config.debug.util")

local M = {}

function M.codelldb_launch()
    return {
        name = "Launch (CodeLLDB)",
        type = "codelldb",
        request = "launch",
        program = function()
            local program = util.choose_program(false)
            util.check_file(program, "Program")
            vim.notify("Program: " .. program)
            return program
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        runInTerminal = false,
        __kind = "native",
    }
end

function M.cppdbg_launch(target)
    target = target or {}
    local gdb = target.gdb or "gdb"

    util.check_executable(gdb, "GDB")

    return {
        name = "Launch (cppdbg)",
        type = "cppdbg",
        request = "launch",

        program = function()
            local program = util.choose_program(false)
            util.check_file(program, "Program")
            return program
        end,

        cwd = "${workspaceFolder}",

        MIMode = "gdb",
        miDebuggerPath = gdb,

        stopAtEntry = false,

        setupCommands = {
            {
                text = "-enable-pretty-printing",
            },
        },
        logging = {
            engineLogging = true,
            trace = true,
            traceResponse = false,
        },

        __kind = "native",
    }
end

function M.build_configuration(target)
    return { M.codelldb_launch(), M.cppdbg_launch(target) }
end

return M
