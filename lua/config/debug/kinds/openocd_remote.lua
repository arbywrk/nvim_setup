-- Embedded/remote debugging via OpenOCD + cppdbg (OpenDebugAD7). cppdbg is
-- used deliberately rather than a native-DAP gdb transport: some vendor
-- GDBs used at work don't support DAP mode and only work through
-- OpenDebugAD7's GDB/MI wrapping.

local util = require("config.debug.util")
local openocd = require("config.debug.openocd")

local M = {}

function M.build_configuration(target)
    local reset_commands = target.reset_commands or {}

    return {
        {
            name = target.name or "OpenOCD (cppdbg)",
            type = "cppdbg",
            request = "attach",

            program = function()
                local program = util.choose_program(false)
                util.check_file(program, "Program")
                return program
            end,

            cwd = "${workspaceFolder}",

            MIMode = "gdb",
            miDebuggerPath = target.gdb,
            miDebuggerServerAddress = target.gdb_target,

            customLaunchSetupCommands = vim.tbl_map(function(cmd)
                return { text = cmd, description = "Reset target", ignoreFailures = false }
            end, reset_commands),

            stopAtEntry = true,

            setupCommands = vim.list_extend(
                {
                    { text = "-enable-pretty-printing" },
                },
                vim.tbl_map(function(cmd)
                    return { text = cmd }
                end, reset_commands)
            ),

            externalConsole = false,

            __kind = "openocd-remote",
            __target = target,
        },
    }
end

M.lifecycle = {
    -- Runs synchronously before the adapter is launched, via dap's
    -- on_config hook -- so OpenOCD is already accepting connections by
    -- the time cppdbg's gdb tries to attach. (A request/response listener
    -- like dap.listeners.before.attach would fire too late: only *after*
    -- that attach attempt already failed.)
    before_launch = function(config)
        openocd.start(config.__target.server, config.__target.gdb_target, config.__target.connect_timeout_ms or 5000)
    end,

    after_stop = function()
        openocd.stop()
    end,
}

return M
