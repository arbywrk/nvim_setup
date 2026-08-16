# Debugging

Debugging is nvim-dap + nvim-dap-ui (`lua/plugins/debug.lua`). Two kinds of
debug configuration exist:

- **Native**, always available: CodeLLDB and cppdbg/gdb launches for
  whatever executable is discovered in the current project (CMake, Cargo,
  Zig, Meson, or plain Makefile build output), or picked manually.
- **Project-registered targets**, e.g. a board reached through OpenOCD.
  Nothing by default -- a project opts in by registering one.

## Registering a project's debug target

Debug targets are project-local data, not something this config hardcodes.
A project registers targets from its own `.nvim.lua` at the project root,
which Neovim only runs if you've explicitly trusted it (see
[Trust](#trust) below):

```lua
-- <project root>/.nvim.lua
require("config.debug").register_target({
    name = "STM32F4 (OpenOCD)",
    kind = "openocd-remote",
    gdb = "arm-none-eabi-gdb",
    gdb_target = "localhost:3333",
    connect_timeout_ms = 5000,
    server = {
        command = "openocd",
        args = { "-f", "interface/stlink.cfg", "-f", "target/stm32f4x.cfg" },
    },
    reset_commands = { "monitor reset halt" },
})
```

Copy `.nvim.lua.example` from this repo as a starting point. Registered
targets are appended to the native defaults in `dap.configurations.c` and
`dap.configurations.cpp`, so both are always available side by side.

### Available kinds

**`native`** (`lua/config/debug/kinds/native.lua`) -- CodeLLDB and
cppdbg/gdb launches. Not something you register; always present.

**`openocd-remote`** (`lua/config/debug/kinds/openocd_remote.lua`) --
spawns an OpenOCD (or any compatible GDB server) process, waits for it to
accept TCP connections, then drives GDB through it via cppdbg/OpenDebugAD7
(GDB/MI), not a native DAP transport. This is deliberate: some vendor
GDBs don't support DAP mode and only work through cppdbg's MI wrapping.
Fields:

| Field                | Meaning                                                             |
|-----------------------|----------------------------------------------------------------------|
| `name`                | Shown in the debug config picker.                                    |
| `gdb`                 | Path/name of the GDB binary to run.                                  |
| `gdb_target`           | `host:port` the GDB server listens on.                                |
| `connect_timeout_ms`   | How long to wait for the server before giving up. Default `5000`.     |
| `server.command`       | GDB server executable (e.g. `openocd`).                              |
| `server.args`          | Args passed to the server.                                           |
| `reset_commands`       | GDB monitor commands run after attaching, before entry stop.          |

## Adding a new debug target kind

The two kinds above don't have to be the only ones. To add another (a
J-Link/ST-Link probe used directly without OpenOCD, a vendor GDB that
speaks DAP natively, QEMU, ...):

1. Create `lua/config/debug/kinds/<your_kind>.lua` exporting:
   - `build_configuration(target)` -- returns a list of nvim-dap
     configuration tables, each tagged `__kind = "<your_kind>"`.
   - `lifecycle = { before_launch = fn(config), after_stop = fn(config) }`
     (optional) -- only needed if your kind manages an external process.
     If it drives a GDB-server-style process, reuse
     `lua/config/debug/openocd.lua`'s `start`/`stop`/`wait_for_tcp` rather
     than reimplementing spawn/teardown/TCP-poll logic.
2. Register it in `lua/config/debug/kinds/init.lua`:
   ```lua
   return {
       native = require("config.debug.kinds.native"),
       ["openocd-remote"] = require("config.debug.kinds.openocd_remote"),
       ["your-kind"] = require("config.debug.kinds.your_kind"),
   }
   ```
3. Use it from a project's `.nvim.lua`:
   ```lua
   require("config.debug").register_target({ kind = "your-kind", ... })
   ```

`debug.lua` itself needs no changes -- it dispatches every registered
target through the kind registry generically, keyed off `target.kind` when
building configs and `config.__kind` when running lifecycle hooks.

## Trust

Project-local `.nvim.lua` files run through Neovim's built-in `'exrc'`
mechanism (`:h 'exrc'`), which is enabled in `lua/options.lua`. The first
time Neovim opens a directory containing an untrusted `.nvim.lua`,
`.nvimrc`, or `.exrc`, it prompts you to `:trust` it. Your decision is
hashed and persisted at `$XDG_STATE_HOME/nvim/trust`; editing the file
later invalidates the hash and re-prompts. Manage trusted files with
`:trust` (see `:h :trust` for `:trust deny`/`:trust remove`/etc).

A hand-rolled data-only format (e.g. JSON) would not have been meaningfully
safer here: the data a debug target supplies -- a GDB path, a server
command and args -- is inherently "what process to spawn", so a real
safety boundary needs a trust gate regardless of file format. This uses
the one Neovim already ships instead of a weaker bespoke one.

## Keymaps

| Key           | Action                          |
|---------------|----------------------------------|
| `<F5>`        | Continue (confirms if no breakpoints set) |
| `<Up>/<Down>/<Left>/<Right>` | Step back/over/out/into |
| `<leader>dr`  | Restart                         |
| `<leader>dp`  | Pause                           |
| `<leader>dq`  | Quit                            |
| `<leader>du`  | Toggle dap-ui                   |
| `<leader>de`  | Force re-select the executable to debug |
| `<leader>db`  | Toggle breakpoint                |
| `<leader>dB`  | Conditional breakpoint            |
