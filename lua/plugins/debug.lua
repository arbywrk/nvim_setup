-----------------------------------------------------------------------
-- Hardcoded debug targets
--
-- Everything project-specific lives here, in one place. Changing
-- projects means editing these tables, not learning a configuration
-- system. Once this has been used for a week or two and it's clear
-- what actually varies between projects, THEN it's worth promoting
-- some of these fields into a .nvim/settings.json format designed
-- around real usage instead of anticipated needs.
-----------------------------------------------------------------------

local util = require("config.debug.util")
local kinds = require("config.debug.kinds")

local embedded = {
    gdb = "arm-none-eabi-gdb",
    target = "localhost:3333",
    connect_timeout_ms = 5000,
}

local openocd = {
    command = "openocd",
    args = {
        "-f",
        "interface/stlink.cfg",
        "-f",
        "target/stm32f4x.cfg",
    },
}

-----------------------------------------------------------------------
-- Debug state
-----------------------------------------------------------------------

local state = {
    server = nil, -- vim.system handle for a running OpenOCD process
}

-----------------------------------------------------------------------
-- Wait for a TCP server to accept connections
--
-- Replaces the old vim.wait(500) guess with an actual connect loop,
-- polling until it succeeds or the timeout elapses.
-----------------------------------------------------------------------

local function wait_for_tcp(target, timeout_ms)
    local host, port = target:match("^(.-):(%d+)$")
    port = tonumber(port)

    if not host or not port then
        error("Invalid target address: " .. tostring(target))
    end

    local deadline = vim.uv.now() + timeout_ms

    while vim.uv.now() < deadline do
        local client = vim.uv.new_tcp()

        if not client then
            error("Could not create a TCP handle (vim.uv.new_tcp() failed)")
        end

        local connected = false
        local finished = false

        client:connect(host, port, function(err)
            connected = (err == nil)
            finished = true

            if not client:is_closing() then
                client:close()
            end
        end)

        vim.wait(200, function()
            return finished
        end, 20)

        if connected then
            return true
        end
    end

    return false
end

-----------------------------------------------------------------------
-- OpenOCD lifecycle
--
-- Kills any server left running from a previous crashed session
-- before starting a fresh one, then blocks (with a real timeout)
-- until it is actually accepting connections.
-----------------------------------------------------------------------

local function stop_server()
    if not state.server then
        return
    end

    pcall(function()
        state.server:kill(vim.loop.constants.SIGTERM)
        state.server:wait(1000)
    end)

    state.server = nil
end

local function start_openocd()
    stop_server() -- in case a previous session died without cleaning up

    util.check_executable(openocd.command, "OpenOCD")

    vim.notify("Starting OpenOCD...", vim.log.levels.INFO)

    state.server =
        vim.system(vim.list_extend({ openocd.command }, openocd.args), { cwd = vim.fn.getcwd(), detach = true })

    vim.notify(("Connecting to %s..."):format(embedded.target), vim.log.levels.INFO)

    if not wait_for_tcp(embedded.target, embedded.connect_timeout_ms) then
        stop_server()
        error(("Timed out waiting for OpenOCD to open %s"):format(embedded.target))
    end

    vim.notify("OpenOCD ready.", vim.log.levels.INFO)
end

-----------------------------------------------------------------------
-- Breakpoint helpers
-----------------------------------------------------------------------

local function has_breakpoints()
    local breakpoints = require("dap.breakpoints").get()

    for _, buffer_breakpoints in pairs(breakpoints) do
        if #buffer_breakpoints > 0 then
            return true
        end
    end

    return false
end

local function continue_with_confirmation()
    local dap = require("dap")

    if dap.session() == nil and not has_breakpoints() then
        local choice = vim.fn.confirm("No breakpoints are set.\nRun anyway?", "&Yes\n&No", 2)

        if choice ~= 1 then
            return
        end
    end

    dap.continue()
end

return {
    "mfussenegger/nvim-dap",

    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",
        "mfussenegger/nvim-dap-python",

        {
            "Weissle/persistent-breakpoints.nvim",
            config = function()
                require("persistent-breakpoints").setup()
            end,
        },
    },

    ----------------------------------------------------------------------
    -- Loading
    --
    -- `keys` drives lazy-loading for actual debug actions. `event =
    -- "VeryLazy"` is ALSO needed: persistent-breakpoints.nvim restores
    -- saved breakpoints via an autocommand registered in its own
    -- setup(), which only runs once this plugin (and thus its
    -- dependency) has loaded. Without an early trigger, nothing loads
    -- it until you first press a debug key -- so any buffer opened
    -- before that point never gets its saved breakpoints restored.
    -- VeryLazy fires shortly after startup without blocking it, which
    -- is early enough for this to work in practice.
    ----------------------------------------------------------------------
    event = "VeryLazy",
    keys = {
        {
            "<F5>",
            function()
                continue_with_confirmation()
            end,
            desc = "Debug: Continue",
        },
        {
            "<Up>",
            function()
                require("dap").step_back()
            end,
            desc = "Debug: Step Back",
        },
        {
            "<Right>",
            function()
                require("dap").step_into()
            end,
            desc = "Debug: Step Into",
        },
        {
            "<Down>",
            function()
                require("dap").step_over()
            end,
            desc = "Debug: Step Over",
        },
        {
            "<Left>",
            function()
                require("dap").step_out()
            end,
            desc = "Debug: Step Out",
        },
        {
            "<leader>dr",
            function()
                require("dap").restart()
            end,
            desc = "Debug: Restart",
        },
        {
            "<leader>dp",
            function()
                require("dap").pause()
            end,
            desc = "Debug: Pause",
        },
        {
            "<leader>dq",
            function()
                require("dap").terminate()
            end,
            desc = "Debug: Quit",
        },
        {
            "<leader>du",
            function()
                require("dapui").toggle()
            end,
            desc = "Debug: Toggle UI",
        },
        {
            "<leader>de",
            function()
                util.choose_program(true)
                vim.notify("Executable: " .. tostring(util.current_program()))
            end,
            desc = "Debug: Select executable",
        },
        {
            "<leader>db",
            function()
                require("persistent-breakpoints.api").toggle_breakpoint()
            end,
            desc = "Debug: Toggle breakpoint",
        },
        {
            "<leader>dB",
            function()
                require("persistent-breakpoints.api").set_conditional_breakpoint()
            end,
            desc = "Debug: Conditional breakpoint",
        },
    },

    config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        ------------------------------------------------------------------------
        -- Mason
        ------------------------------------------------------------------------

        require("mason-nvim-dap").setup({
            automatic_installation = true,
            handlers = {},
            ensure_installed = {
                "codelldb",
                "cppdbg",
                "debugpy",
                "kotlin-debug-adapter",
            },
        })

        ------------------------------------------------------------------------
        -- UI
        ------------------------------------------------------------------------

        dapui.setup({
            icons = {
                expanded = "",
                collapsed = "",
                current_frame = "󰁕",
            },
            controls = {
                enabled = true,
                element = "repl",
                icons = {
                    pause = "󰏤",
                    play = "󰐊",
                    step_into = "󰆹",
                    step_over = "󰆷",
                    step_out = "󰆸",
                    step_back = "󰁯",
                    run_last = "󰑓",
                    terminate = "󰅖",
                    disconnect = "󰿅",
                },
            },

            wrap = true,
            expand_lines = true,
            force_buffers = true,

            mappings = {
                expand = { "<CR>", "<2-LeftMouse>" },
                open = "o",
                remove = "d",
                edit = "e",
                repl = "r",
                toggle = "t",
            },

            -- per-element mapping overrides; empty means "use `mappings` above
            -- everywhere" -- explicit here so the type is fully satisfied
            -- rather than relying on dapui filling in a default.
            element_mappings = {},

            ------------------------------------------------------------
            -- Layout: left sidebar for state, bottom panel for I/O --
            -- this is the part that actually makes it feel like an
            -- IDE's debug view instead of a single floating window.
            ------------------------------------------------------------
            layouts = {
                {
                    elements = {
                        { id = "scopes", size = 0.40 },
                        { id = "breakpoints", size = 0.20 },
                        { id = "stacks", size = 0.20 },
                        { id = "watches", size = 0.20 },
                    },
                    size = 45,
                    position = "left",
                },
                {
                    elements = {
                        { id = "repl", size = 0.55 },
                        { id = "console", size = 0.45 },
                    },
                    size = 12,
                    position = "bottom",
                },
            },

            floating = {
                max_height = 0.7,
                max_width = 0.6,
                border = "rounded",
                mappings = {
                    close = { "q", "<Esc>" },
                },
            },

            render = {
                max_type_length = nil,
                max_value_lines = 100,
                indent = 1,
            },
        })

        ------------------------------------------------------------------------
        -- Inline virtual text (variable values shown next to the line while
        -- stepping, like most IDEs). This plugin was already listed as a
        -- dependency but never actually configured -- without setup() it
        -- does nothing.
        ------------------------------------------------------------------------

        require("nvim-dap-virtual-text").setup({
            enabled = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = true,
            show_stop_reason = true,
            commented = false,
            virt_text_pos = "eol",
            all_frames = false,
        })

        ------------------------------------------------------------------------
        -- Signs & highlights
        ------------------------------------------------------------------------

        vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
        vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00", bold = true })
        vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#3d3300" })
        vim.api.nvim_set_hl(0, "DapUIVariable", { fg = "#c5c8c6" })
        vim.api.nvim_set_hl(0, "DapUIValue", { fg = "#8abeb7" })
        vim.api.nvim_set_hl(0, "DapUIScope", { fg = "#81a2be", bold = true })
        vim.api.nvim_set_hl(0, "DapUIType", { fg = "#b294bb" })
        vim.api.nvim_set_hl(0, "DapUIWatchesValue", { fg = "#b5bd68" })
        vim.api.nvim_set_hl(0, "DapUIBreakpointsPath", { fg = "#81a2be" })
        vim.api.nvim_set_hl(0, "DapUIBreakpointsInfo", { fg = "#b5bd68" })
        vim.api.nvim_set_hl(0, "DapUIFrameName", { fg = "#c5c8c6" })
        vim.api.nvim_set_hl(0, "DapUIThread", { fg = "#b5bd68", bold = true })
        vim.api.nvim_set_hl(0, "DapUIStoppedThread", { fg = "#ffcc00", bold = true })

        local breakpoint_icons = vim.g.have_nerd_font
                and {
                    Breakpoint = "󰃤",
                    BreakpointCondition = "󰘥",
                    BreakpointRejected = "󰚌",
                    LogPoint = "󰍩",
                    Stopped = "󰁕",
                }
            or {
                Breakpoint = "●",
                BreakpointCondition = "?",
                BreakpointRejected = "×",
                LogPoint = "◆",
                Stopped = "▶",
            }

        for kind, icon in pairs(breakpoint_icons) do
            local hl = kind == "Stopped" and "DapStop" or "DapBreak"

            vim.fn.sign_define("Dap" .. kind, {
                text = icon,
                texthl = hl,
                numhl = hl,
                -- highlight the full stopped line, like an IDE execution marker
                linehl = kind == "Stopped" and "DapStoppedLine" or nil,
            })
        end

        ------------------------------------------------------------------------
        -- UI lifecycle
        --
        -- OpenOCD is only started for the embedded ("attach") session --
        -- native GDB and CodeLLDB launches never touch it.
        ------------------------------------------------------------------------

        dap.listeners.before.launch.openocd = function(config)
            if config.name == "OpenOCD" then
                start_openocd()
            end
        end

        dap.listeners.after.event_initialized["dapui"] = function()
            dapui.open()
        end

        dap.listeners.before.event_terminated["dapui"] = function()
            dapui.close()
            stop_server()
        end

        dap.listeners.before.event_exited["dapui"] = function()
            dapui.close()
            stop_server()
        end

        ------------------------------------------------------------------------
        -- Adapters
        --
        -- adapter / launch / attach kept as separate, named pieces so a
        -- broken adapter is easy to tell apart from a broken launch
        -- request when something goes wrong.
        ------------------------------------------------------------------------

        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
                args = { "--port", "${port}" },
            },
        }

        util.check_executable(vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7", "OpenDebugAD7")

        dap.adapters.cppdbg = {
            id = "cppdbg",
            type = "executable",
            command = vim.fn.stdpath("data") .. "/mason/bin/OpenDebugAD7",
        }

        ------------------------------------------------------------------------
        -- Launch / attach configurations
        --
        -- Native (CodeLLDB + cppdbg) configs come from the "native" kind
        -- module. Embedded/remote is still inline here for now -- it moves
        -- into its own kind module in a follow-up commit.
        ------------------------------------------------------------------------

        local function cppdbg_remote()
            -- util.check_executable(embedded.gdb, "ARM GDB")
            return {
                name = "cppdbg + OpenOCD",
                type = "cppdbg",
                request = "attach",

                program = function()
                    local program = util.choose_program(false)
                    util.check_file(program, "Program")
                    return program
                end,

                cwd = "${workspaceFolder}",

                MIMode = "gdb",
                miDebuggerPath = embedded.gdb,

                miDebuggerServerAddress = embedded.target,

                customLaunchSetupCommands = {
                    {
                        text = "monitor reset halt",
                        description = "Reset target",
                        ignoreFailures = false,
                    },
                },

                stopAtEntry = true,

                setupCommands = {
                    {
                        text = "-enable-pretty-printing",
                    },
                    {
                        text = "monitor reset halt",
                    },
                },

                externalConsole = false,
            }
        end

        dap.configurations.c = vim.list_extend(kinds.native.build_configuration(), { cppdbg_remote() })
        dap.configurations.cpp = vim.list_extend(kinds.native.build_configuration(), { cppdbg_remote() })

        dap.configurations.zig = {
            kinds.native.codelldb_launch(),
        }

        ------------------------------------------------------------------------
        -- Python (debugpy)
        ------------------------------------------------------------------------

        require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")

        ------------------------------------------------------------------------
        -- Kotlin
        ------------------------------------------------------------------------

        dap.adapters.kotlin = {
            type = "executable",
            command = vim.fn.stdpath("data") .. "/mason/bin/kotlin-debug-adapter",
        }

        dap.configurations.kotlin = {
            {
                name = "Launch Kotlin",
                type = "kotlin",
                request = "launch",
                projectRoot = "${workspaceFolder}",
                mainClass = function()
                    return vim.fn.input("Main class (e.g. com.example.MainKt): ")
                end,
            },
        }
    end,
}
