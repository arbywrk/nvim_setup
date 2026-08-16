-- Registry for per-project build profiles.
--
-- A trusted project-local `.nvim.lua` (see :h 'exrc') calls
-- require("config.build").register_profile({...}) to add itself. Each
-- profile may define any of build/flash/clean = { command, args }.

local M = {}

local profiles = {}
local current = nil

function M.register_profile(profile)
    table.insert(profiles, profile)

    if not current then
        current = profile
    end
end

function M.profiles()
    return profiles
end

-- Returns the current profile, prompting to pick one if forced (or if
-- there's more than one and none has been picked yet).
function M.select(force)
    if not force and current then
        return current
    end

    if #profiles == 0 then
        vim.notify("No build profiles registered for this project", vim.log.levels.WARN)
        return nil
    end

    if #profiles == 1 then
        current = profiles[1]
        return current
    end

    vim.ui.select(profiles, {
        prompt = "Build profile",
        format_item = function(profile)
            return profile.name or "unnamed"
        end,
    }, function(choice)
        current = choice
    end)

    return current
end

return M
