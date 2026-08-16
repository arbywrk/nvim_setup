-----------------------------------------------------------------------
-- Debug adapter/target setup
--
-- Native (CodeLLDB/cppdbg) configs are always available, from
-- config/debug/kinds/native.lua. Project-specific targets (e.g. a board
-- reached through OpenOCD) are added by a trusted project-local
-- .nvim.lua (see :h 'exrc') calling
-- require("config.debug").register_target({...}) -- see doc/debugging.md.
-----------------------------------------------------------------------

local util = require("config.debug.util")
local kinds = require("config.debug.kinds")
local debug_config = require("config.debug")
local keymap = require("util.keymap")

local dap = require("dap")
local dapui = require("dapui")

-- Builds the dap.configurations list for c/cpp: native defaults plus
-- whatever a project's .nvim.lua registered, dispatched through each
-- target's own kind module.
local function project_configurations()
    local configs = kinds.native.build_configuration()

    for _, target in ipairs(debug_config.targets()) do
        local kind = kinds[target.kind]

        if kind then
            vim.list_extend(configs, kind.build_configuration(target))
        else
            vim.notify(("Unknown debug target kind: %s"):format(tostring(target.kind)), vim.log.levels.WARN)
        end
    end

    return configs
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
    if dap.session() == nil and not has_breakpoints() then
        local choice = vim.fn.confirm("No breakpoints are set.\nRun anyway?", "&Yes\n&No", 2)

        if choice ~= 1 then
            return
        end
    end

    dap.continue()
end

-----------------------------------------------------------------------
-- Keymaps
-----------------------------------------------------------------------

keymap.map("n", "<F5>", continue_with_confirmation, "Debug: Continue")

keymap.map("n", "<Up>", function()
    dap.step_back()
end, "Debug: Step Back")

keymap.map("n", "<Right>", function()
    dap.step_into()
end, "Debug: Step Into")

keymap.map("n", "<Down>", function()
    dap.step_over()
end, "Debug: Step Over")

keymap.map("n", "<Left>", function()
    dap.step_out()
end, "Debug: Step Out")

keymap.map("n", "<leader>dr", function()
    dap.restart()
end, "Debug: Restart")

keymap.map("n", "<leader>dp", function()
    dap.pause()
end, "Debug: Pause")

keymap.map("n", "<leader>dq", function()
    dap.terminate()
end, "Debug: Quit")

keymap.map("n", "<leader>du", function()
    dapui.toggle()
end, "Debug: Toggle UI")

keymap.map("n", "<leader>de", function()
    util.choose_program(true)
    vim.notify("Executable: " .. tostring(util.current_program()))
end, "Debug: Select executable")

keymap.map("n", "<leader>db", function()
    require("persistent-breakpoints.api").toggle_breakpoint()
end, "Debug: Toggle breakpoint")

keymap.map("n", "<leader>dB", function()
    require("persistent-breakpoints.api").set_conditional_breakpoint()
end, "Debug: Conditional breakpoint")

keymap.map("n", "<leader>dt", function()
    local targets = debug_config.targets()

    if #targets == 0 then
        vim.notify("No debug targets registered for this project", vim.log.levels.WARN)
        return
    end

    vim.ui.select(targets, {
        prompt = "Debug target",
        format_item = function(target)
            return target.name or target.kind
        end,
    }, function(target)
        if not target then
            return
        end

        local kind = kinds[target.kind]
        if not kind then
            vim.notify(("Unknown debug target kind: %s"):format(tostring(target.kind)), vim.log.levels.WARN)
            return
        end

        dap.run(kind.build_configuration(target)[1])
    end)
end, "Debug: Select target")

-----------------------------------------------------------------------
-- Breakpoint persistence
-----------------------------------------------------------------------

require("persistent-breakpoints").setup()

------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------

dapui.setup({
    icons = {
        expanded = "",
        collapsed = "",
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
-- stepping, like most IDEs).
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
-- Generic per-kind lifecycle dispatch, keyed off each built config's own
-- __kind field. Uses on_config (fires synchronously before the adapter
-- is launched) rather than a request/response listener like
-- dap.listeners.before.attach: a response-time hook would only fire
-- *after* cppdbg's gdb already tried and failed to attach, which is too
-- late to have started OpenOCD.
------------------------------------------------------------------------

dap.listeners.on_config["debug-kinds"] = function(config)
    local kind = kinds[config.__kind]

    if kind and kind.lifecycle and kind.lifecycle.before_launch then
        kind.lifecycle.before_launch(config)
    end

    return config
end

local function stop_kind_lifecycle(session)
    local kind_config = session and session.config
    local kind = kind_config and kinds[kind_config.__kind]

    if kind and kind.lifecycle and kind.lifecycle.after_stop then
        kind.lifecycle.after_stop(kind_config)
    end
end

dap.listeners.after.event_initialized["dapui"] = function()
    dapui.open()
end

dap.listeners.before.event_terminated["dapui"] = function(session)
    dapui.close()
    stop_kind_lifecycle(session)
end

dap.listeners.before.event_exited["dapui"] = function(session)
    dapui.close()
    stop_kind_lifecycle(session)
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
        command = "codelldb",
        args = { "--port", "${port}" },
    },
}

util.check_executable("OpenDebugAD7", "OpenDebugAD7")

dap.adapters.cppdbg = {
    id = "cppdbg",
    type = "executable",
    command = "OpenDebugAD7",
}

------------------------------------------------------------------------
-- Launch / attach configurations
--
-- Native configs are always present; project-registered targets
-- (see project_configurations() above) are appended on top.
------------------------------------------------------------------------

dap.configurations.c = project_configurations()
dap.configurations.cpp = project_configurations()

dap.configurations.zig = {
    kinds.native.codelldb_launch(),
}

------------------------------------------------------------------------
-- Python (debugpy)
------------------------------------------------------------------------

require("dap-python").setup("debugpy-python")
