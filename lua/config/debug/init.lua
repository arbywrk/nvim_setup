-- Registry for per-project debug targets.
--
-- A trusted project-local `.nvim.lua` (see :h 'exrc') calls
-- require("config.debug").register_target({...}) to add itself. Nothing
-- reads this list until dap.configurations.c/cpp are built, so registration
-- order relative to plugin loading doesn't matter.

local M = {}

local targets = {}

function M.register_target(target)
    table.insert(targets, target)
end

function M.targets()
    return targets
end

return M
