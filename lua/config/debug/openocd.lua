-- Shared OpenOCD process lifecycle: spawn, wait for the GDB server port to
-- accept connections, and tear down. Split out from any single debug kind
-- so a future kind for vendor GDBs that speak DAP natively (rather than
-- through cppdbg/OpenDebugAD7) can reuse this without duplicating it --
-- only the "how do we talk to gdb" transport differs between kinds, not
-- the OpenOCD orchestration itself.

local util = require("config.debug.util")

local M = {}

local state = {
    server = nil, -- vim.system handle for a running OpenOCD process
}

-- Replaces a fixed-delay guess with an actual connect loop, polling until
-- it succeeds or the timeout elapses.
function M.wait_for_tcp(target, timeout_ms)
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

function M.stop()
    if not state.server then
        return
    end

    pcall(function()
        state.server:kill(vim.loop.constants.SIGTERM)
        state.server:wait(1000)
    end)

    state.server = nil
end

-- server_cfg: { command = "openocd", args = {...} }
function M.start(server_cfg, target_addr, timeout_ms)
    M.stop() -- in case a previous session died without cleaning up

    util.check_executable(server_cfg.command, "OpenOCD")

    vim.notify(("Starting %s..."):format(server_cfg.command), vim.log.levels.INFO)

    state.server =
        vim.system(vim.list_extend({ server_cfg.command }, server_cfg.args), { cwd = vim.fn.getcwd(), detach = true })

    vim.notify(("Connecting to %s..."):format(target_addr), vim.log.levels.INFO)

    if not M.wait_for_tcp(target_addr, timeout_ms) then
        M.stop()
        error(("Timed out waiting for %s to open %s"):format(server_cfg.command, target_addr))
    end

    vim.notify(("%s ready."):format(server_cfg.command), vim.log.levels.INFO)
end

return M
