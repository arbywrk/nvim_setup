-----------------------------------------------------------------------
-- Adding a new debug target kind
--
-- 1. Write a module under lua/config/debug/kinds/ that exports:
--      build_configuration(target) -> a list of nvim-dap configuration
--        tables, each tagged with __kind = "<your-kind-name>".
--      lifecycle = { before_launch = fn(config), after_stop = fn(config) }
--        (optional -- only needed if your kind manages an external
--        process, e.g. a GDB server. See openocd_remote.lua for an
--        example, and reuse config/debug/openocd.lua if you're also
--        driving OpenOCD.)
-- 2. Register the module below under a chosen kind string.
-- 3. From a project's .nvim.lua, call:
--      require("config.debug").register_target({ kind = "<your-kind-name>", ... })
-----------------------------------------------------------------------

return {
    native = require("config.debug.kinds.native"),
}
