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

local native = {
    gdb = "gdb",
}

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
    program = nil,
    server = nil, -- vim.system handle for a running OpenOCD process
}

-----------------------------------------------------------------------
-- Executable discovery (unchanged -- this part already works well)
-----------------------------------------------------------------------

local function is_executable(path)
    return vim.fn.filereadable(path) == 1 and vim.fn.executable(path) == 1
end

local function add_all(results, pattern)
    for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
        if is_executable(file) then
            table.insert(results, vim.fs.normalize(file))
        end
    end
end

local function discover_executables()
    local cwd = vim.fn.getcwd()
    local executables = {}

    -------------------------------------------------------------
    -- Zig
    -------------------------------------------------------------
    if vim.uv.fs_stat(cwd .. "/build.zig") then
        add_all(executables, cwd .. "/zig-out/bin/*")
    end

    -------------------------------------------------------------
    -- Cargo
    -------------------------------------------------------------
    if vim.uv.fs_stat(cwd .. "/Cargo.toml") then
        add_all(executables, cwd .. "/target/debug/*")
    end

    -------------------------------------------------------------
    -- Meson
    -------------------------------------------------------------
    if vim.uv.fs_stat(cwd .. "/meson.build") then
        add_all(executables, cwd .. "/build/**/*")
    end

    -------------------------------------------------------------
    -- CMake
    -------------------------------------------------------------
    if vim.uv.fs_stat(cwd .. "/CMakeLists.txt") then
        add_all(executables, cwd .. "/build/**/*")

        for _, dir in ipairs(vim.fn.glob(cwd .. "/cmake-build-*", false, true)) do
            add_all(executables, dir .. "/**/*")
        end
    end

    -------------------------------------------------------------
    -- Generic Make
    -------------------------------------------------------------
    if vim.uv.fs_stat(cwd .. "/Makefile") then
        add_all(executables, cwd .. "/bin/*")
        add_all(executables, cwd .. "/build/*")
        add_all(executables, cwd .. "/*")
    end

    return vim.fn.uniq(vim.fn.sort(executables))
end

-----------------------------------------------------------------------
-- Program selection
--
-- No more reading a program path out of settings.json -- just cache
-- the last choice and re-discover / re-prompt when asked to.
-----------------------------------------------------------------------

local function choose_program(force)
    if not force and state.program and vim.uv.fs_stat(state.program) then
        return state.program
    end

    local executables = discover_executables()

    if #executables == 1 then
        state.program = executables[1]
        return state.program
    end

    if #executables > 1 then
        local done = false

        vim.ui.select(executables, {
            prompt = "Executable",
        }, function(choice)
            state.program = choice
            done = true
        end)

        vim.wait(10000, function()
            return done
        end)

        if state.program then
            return state.program
        end
    end

    state.program = vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")

    return state.program
end

-----------------------------------------------------------------------
-- Health checks
--
-- Fail loudly and immediately, before DAP has started anything, not
-- partway through a launch sequence.
-----------------------------------------------------------------------

local function check_executable(path, label)
    if vim.fn.executable(path) == 0 then
        error(("%s not found on PATH: %s"):format(label, path))
    end
end

local function check_file(path, label)
    if not path or path == "" or not vim.uv.fs_stat(path) then
        error(("%s not found: %s"):format(label, tostring(path)))
    end
end

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
        state.server:kill(15)
    end)

    state.server = nil
end

local function start_openocd()
    stop_server() -- in case a previous session died without cleaning up

    check_executable(openocd.command, "OpenOCD")

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
                choose_program(true)
                vim.notify("Executable: " .. tostring(state.program))
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

        dap.listeners.before.attach["openocd"] = function(_, body)
            if body and body.type == "gdb_embedded" then
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

        local function gdb_native_adapter(callback)
            check_executable(native.gdb, "GDB")

            callback({
                id = "gdb_native",
                type = "executable",
                command = native.gdb,
                args = { "--quiet", "--interpreter=dap" },
            })
        end

        local function gdb_embedded_adapter(callback)
            check_executable(embedded.gdb, "GDB (embedded)")

            callback({
                id = "gdb_embedded",
                type = "executable",
                command = embedded.gdb,
                args = { "--quiet", "--interpreter=dap" },
            })
        end

        dap.adapters.gdb_native = function(callback)
            gdb_native_adapter(callback)
        end

        dap.adapters.gdb_embedded = function(callback)
            gdb_embedded_adapter(callback)
        end

        ------------------------------------------------------------------------
        -- Launch / attach configurations
        --
        -- Three explicit configurations, no hidden branching between
        -- native and embedded. Each prints what it's about to do and
        -- checks its own preconditions before DAP starts anything.
        ------------------------------------------------------------------------

        local function codelldb_launch()
            return {
                name = "Launch (CodeLLDB)",
                type = "codelldb",
                request = "launch",
                program = function()
                    local program = choose_program(false)
                    check_file(program, "Program")
                    vim.notify("Program: " .. program)
                    return program
                end,
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
                runInTerminal = false,
            }
        end

        local function gdb_native_launch()
            return {
                name = "Launch (GDB Native)",
                type = "gdb_native",
                request = "launch",
                program = function()
                    local program = choose_program(false)
                    check_file(program, "Program")
                    vim.notify("Using " .. native.gdb)
                    vim.notify("Program: " .. program)
                    return program
                end,
                cwd = "${workspaceFolder}",
                stopAtBeginningOfMainSubprogram = false,
            }
        end

        local function openocd_attach()
            return {
                name = "Attach (OpenOCD)",
                type = "gdb_embedded",
                request = "attach",
                target = embedded.target,
                program = function()
                    local program = choose_program(false)
                    check_file(program, "Program")
                    vim.notify("Using " .. embedded.gdb)
                    vim.notify("Program: " .. program)
                    return program
                end,
                cwd = "${workspaceFolder}",
            }
        end

        dap.configurations.c = {
            codelldb_launch(),
            gdb_native_launch(),
            openocd_attach(),
        }

        dap.configurations.cpp = {
            codelldb_launch(),
            gdb_native_launch(),
            openocd_attach(),
        }

        dap.configurations.zig = {
            codelldb_launch(),
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
