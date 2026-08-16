-- Shared helpers for debug target kinds: executable discovery/selection
-- and precondition checks that fail loudly, before DAP starts anything,
-- rather than partway through a launch sequence.

local M = {}

local state = {
    program = nil,
}

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

function M.discover_executables()
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

function M.choose_program(force)
    if not force and state.program and vim.uv.fs_stat(state.program) then
        return state.program
    end

    local executables = M.discover_executables()

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

function M.current_program()
    return state.program
end

function M.check_executable(path, label)
    if vim.fn.executable(path) == 0 then
        error(("%s not found on PATH: %s"):format(label, path))
    end
end

function M.check_file(path, label)
    if not path or path == "" or not vim.uv.fs_stat(path) then
        error(("%s not found: %s"):format(label, tostring(path)))
    end
end

return M
