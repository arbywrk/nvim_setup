-- Project build/flash/clean actions. Nothing by default -- a project
-- registers profiles via require("config.build").register_profile({...})
-- from its trusted .nvim.lua (see doc/debugging.md for the trust
-- mechanism; build profiles use the same one).

local keymap = require("util.keymap")
local build_config = require("config.build")

-- Plain built-in terminal (no toggleterm dependency): a bottom split
-- running the command directly, left open after exit so output/errors
-- stay visible.
local function run(step)
    local profile = build_config.select(false)

    if not profile then
        return
    end

    local step_cfg = profile[step]

    if not step_cfg or not step_cfg.command then
        vim.notify(("Profile %q has no %s step"):format(profile.name or "?", step), vim.log.levels.WARN)
        return
    end

    local cmd = vim.list_extend({ step_cfg.command }, step_cfg.args or {})
    local root = vim.fs.root(0, ".git") or vim.fn.getcwd()

    vim.cmd("botright split")
    vim.fn.jobstart(cmd, { term = true, cwd = root })
    vim.cmd("startinsert")
end

keymap.map("n", "<leader>mb", function()
    run("build")
end, "Build: Run build")

keymap.map("n", "<leader>mf", function()
    run("flash")
end, "Build: Flash")

keymap.map("n", "<leader>mc", function()
    run("clean")
end, "Build: Clean")

keymap.map("n", "<leader>mt", function()
    local profile = build_config.select(true)

    if profile then
        vim.notify("Build profile: " .. (profile.name or "?"))
    end
end, "Build: Select profile")
