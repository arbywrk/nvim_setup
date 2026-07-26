-----------------------------------------------------------------------
-- Debug state
-----------------------------------------------------------------------

local state = {
    program = nil,
    gdb = nil,
    server = nil,
}

-----------------------------------------------------------------------
-- Executable discovery
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
-- Project-local settings (.nvim/settings.json)
-----------------------------------------------------------------------

local function find_upward(relative_path)
    local dir = vim.fn.getcwd()

    while dir and dir ~= "" do
        local candidate = dir .. "/" .. relative_path

        if vim.uv.fs_stat(candidate) then
            return candidate
        end

        local parent = vim.fs.dirname(dir)

        if parent == dir then
            break
        end

        dir = parent
    end

    return nil
end

local function settings_path()
    return find_upward(".nvim/settings.json") or (vim.fn.getcwd() .. "/.nvim/settings.json")
end

local function read_settings()
    local path = settings_path()

    if not vim.uv.fs_stat(path) then
        return {}
    end

    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then
        return {}
    end

    local ok2, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))

    if not ok2 or type(decoded) ~= "table" then
        return {}
    end

    return decoded
end

local function write_settings(settings)
    local path = settings_path()
    local dir = vim.fs.dirname(path)

    if not vim.uv.fs_stat(dir) then
        vim.fn.mkdir(dir, "p")
    end

    local ok, encoded = pcall(vim.json.encode, settings)

    if not ok then
        vim.notify("Failed writing settings.json", vim.log.levels.ERROR)
        return
    end

    vim.fn.writefile(vim.split(encoded, "\n"), path)
end

-----------------------------------------------------------------------
-- Debugger settings
-----------------------------------------------------------------------

local function project_debug_settings()
    return read_settings().debugger or {}
end

-----------------------------------------------------------------------
-- Program selection
-----------------------------------------------------------------------

local function choose_program(force)
    local settings = project_debug_settings()

    if not force and settings.program then
        local path = settings.program

        if not vim.startswith(path, "/") then
            path = vim.fn.getcwd() .. "/" .. path
        end

        path = vim.fs.normalize(path)

        if vim.uv.fs_stat(path) then
            state.program = path
            return path
        end
    end

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
-- GDB selection
-----------------------------------------------------------------------

local function choose_gdb(force)
    local settings = project_debug_settings()

    if not force and settings.gdb and vim.fn.executable(settings.gdb) == 1 then
        state.gdb = settings.gdb
        return state.gdb
    end

    if not force and state.gdb and vim.fn.executable(state.gdb) == 1 then
        return state.gdb
    end

    state.gdb = vim.fn.input("GDB executable: ", state.gdb or "gdb")

    if state.gdb == "" then
        state.gdb = "gdb"
    end

    return state.gdb
end

-----------------------------------------------------------------------
-- Generic debug server
-----------------------------------------------------------------------

local function start_server()
    if state.server then
        return
    end

    local settings = project_debug_settings()
    local server = settings.server

    if not server then
        return
    end

    local command = server.command

    if not command or command == "" then
        vim.notify("Debugger server has no command configured.", vim.log.levels.ERROR)
        return
    end

    local args = server.args or {}

    vim.notify("Starting debug server: " .. command, vim.log.levels.INFO)

    state.server = vim.system(vim.list_extend({ command }, args), {
        cwd = vim.fn.getcwd(),
        detach = true,
    })

    vim.wait(server.startup_delay or 500)
end

local function stop_server()
    if not state.server then
        return
    end

    pcall(function()
        state.server:kill(15)
    end)

    state.server = nil
end

-----------------------------------------------------------------------
-- Project-local dap.lua
-----------------------------------------------------------------------

local function load_project_dap_config()
    local path = find_upward(".nvim/dap.lua")

    if not path then
        return nil
    end

    local ok, result = pcall(dofile, path)

    if not ok then
        vim.notify("Failed loading " .. path .. "\n\n" .. tostring(result), vim.log.levels.ERROR)
        return nil
    end

    if type(result) ~= "table" then
        vim.notify(path .. " must return a table.", vim.log.levels.ERROR)
        return nil
    end

    return result
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

    if _G.NvimDapSyncConfigurations then
        _G.NvimDapSyncConfigurations()
    end

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
                state.program = nil
                choose_program(true)
                vim.notify("Executable: " .. state.program)
            end,
            desc = "Debug: Select executable",
        },
        {
            "<leader>dg",
            function()
                state.gdb = nil
                choose_gdb(true)
                vim.notify("GDB: " .. state.gdb)
            end,
            desc = "Debug: Select GDB executable",
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
                current_frame = "",
            },
            controls = {
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
        })

        ------------------------------------------------------------------------
        -- Signs
        ------------------------------------------------------------------------

        vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
        vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })

        local breakpoint_icons = vim.g.have_nerd_font
                and {
                    Breakpoint = "",
                    BreakpointCondition = "",
                    BreakpointRejected = "",
                    LogPoint = "󰍩",
                    Stopped = "",
                }
            or {
                Breakpoint = "●",
                BreakpointCondition = "⊜",
                BreakpointRejected = "⊘",
                LogPoint = "◆",
                Stopped = "⭔",
            }

        for kind, icon in pairs(breakpoint_icons) do
            local hl = kind == "Stopped" and "DapStop" or "DapBreak"

            vim.fn.sign_define("Dap" .. kind, {
                text = icon,
                texthl = hl,
                numhl = hl,
            })
        end

        ------------------------------------------------------------------------
        -- UI lifecycle
        ------------------------------------------------------------------------

        dap.listeners.before.launch["debug_server"] = start_server
        dap.listeners.before.attach["debug_server"] = start_server

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
        ------------------------------------------------------------------------

        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
                args = { "--port", "${port}" },
            },
        }

        dap.adapters.gdb = function(callback, config)
            local settings = project_debug_settings()

            callback({
                id = "gdb",
                type = "executable",
                command = config.gdbPath or settings.gdb or choose_gdb(false),
                args = {
                    "--quiet",
                    "--interpreter=dap",
                },
            })
        end

        ------------------------------------------------------------------------
        -- Built-in launch configurations
        ------------------------------------------------------------------------

        local function codelldb_launch()
            return {
                name = "Launch (CodeLLDB)",
                type = "codelldb",
                request = "launch",

                program = function()
                    return choose_program(false)
                end,

                cwd = "${workspaceFolder}",
                stopOnEntry = false,
                runInTerminal = false,
            }
        end

        local function gdb_launch()
            local settings = project_debug_settings()

            local cfg = {
                name = "Launch (GDB)",
                type = "gdb",
                request = "launch",

                program = function()
                    return choose_program(false)
                end,

                cwd = "${workspaceFolder}",

                target = settings.target,

                gdbPath = settings.gdb,

                stopAtBeginningOfMainSubprogram = false,
            }

            if settings.gdbinit and settings.gdbinit ~= "" then
                cfg.setupCommands = {
                    {
                        text = "source " .. settings.gdbinit,
                    },
                }
            end

            return cfg
        end

        ------------------------------------------------------------------------
        -- Configuration sync
        ------------------------------------------------------------------------

        _G.NvimDapSyncConfigurations = function()
            dap.configurations.c = {
                codelldb_launch(),
                gdb_launch(),
            }

            dap.configurations.cpp = {
                codelldb_launch(),
                gdb_launch(),
            }

            dap.configurations.zig = {
                codelldb_launch(),
            }

            local project = load_project_dap_config()

            if project then
                for ft, configs in pairs(project) do
                    dap.configurations[ft] = dap.configurations[ft] or {}
                    vim.list_extend(dap.configurations[ft], configs)
                end
            end
        end

        ------------------------------------------------------------------------
        -- Helpers for .nvim/dap.lua
        ------------------------------------------------------------------------

        _G.NvimDapHelpers = {
            choose_program = choose_program,
            choose_gdb = choose_gdb,
            settings = project_debug_settings,
        }

        _G.NvimDapSyncConfigurations()

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
