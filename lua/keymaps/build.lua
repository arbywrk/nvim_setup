-- Project build/flash/clean actions. Nothing by default -- a project
-- registers profiles via require("config.build").register_profile({...})
-- from its trusted .nvim.lua (see doc/debugging.md for the trust
-- mechanism; build profiles use the same one).

local keymap = require("util.keymap")
local build_config = require("config.build")

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

    local Terminal = require("toggleterm.terminal").Terminal

    Terminal:new({
        cmd = vim.list_extend({ step_cfg.command }, step_cfg.args or {}),
        dir = "git_dir",
        direction = "horizontal",
        close_on_exit = false,
    }):toggle()
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
