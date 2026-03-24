local util = require("lspconfig.util")
local unpack_fn = table.unpack or unpack

local M = {}

local esp_root_markers = {
	"sdkconfig",
	"idf_component.yml",
	"managed_components",
}

local project_root_markers = {
	"sdkconfig",
	"idf_component.yml",
	"managed_components",
	"compile_commands.json",
	"compile_flags.txt",
	".clangd",
	".git",
}

local format_group = vim.api.nvim_create_augroup("user-clangd-format", { clear = false })

local resolved = {
	esp_clangd = nil,
	esp_drivers = nil,
}

local function latest_match(pattern)
	local matches = vim.fn.glob(pattern, true, true)
	table.sort(matches)
	return matches[#matches]
end

local function glob_matches(pattern)
	local matches = vim.fn.glob(pattern, true, true)
	table.sort(matches)
	return matches
end

local function dedupe(items)
	local seen = {}
	local result = {}

	for _, item in ipairs(items) do
		if not seen[item] then
			seen[item] = true
			table.insert(result, item)
		end
	end

	return result
end

local function read_style_file(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end

	local style = {}

	for _, line in ipairs(lines) do
		local indent_width = line:match("^%s*IndentWidth:%s*(%d+)")
		if indent_width then
			style.indent_width = tonumber(indent_width)
		end

		local tab_width = line:match("^%s*TabWidth:%s*(%d+)")
		if tab_width then
			style.tab_width = tonumber(tab_width)
		end

		local use_tab = line:match("^%s*UseTab:%s*(%S+)")
		if use_tab then
			style.use_tab = use_tab
		end
	end

	return style
end

local function find_style_file(bufnr)
	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return nil
	end

	return vim.fs.find({ ".clang-format", "_clang-format" }, {
		path = vim.fs.dirname(filename),
		upward = true,
	})[1]
end

local function shared_cmd(binary)
	return {
		binary,
		"--background-index",
		"--completion-style=detailed",
		"--function-arg-placeholders",
	}
end

local function default_cmd()
	local cmd = shared_cmd("clangd")
	table.insert(cmd, "--clang-tidy")
	table.insert(cmd, "--header-insertion=iwyu")
	return cmd
end

local function normalize_bufname(bufnr)
	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return nil
	end

	return vim.fs.normalize(filename)
end

local function esp_clangd_path()
	if resolved.esp_clangd ~= nil then
		return resolved.esp_clangd or nil
	end

	resolved.esp_clangd = latest_match("~/.espressif/tools/esp-clang/*/esp-clang/bin/clangd") or false
	return resolved.esp_clangd or nil
end

local function esp_toolchain_drivers()
	if resolved.esp_drivers ~= nil then
		return resolved.esp_drivers
	end

	local drivers = {}
	vim.list_extend(drivers, glob_matches(vim.fn.expand("~/.espressif/tools/riscv32-esp-elf/*/riscv32-esp-elf/bin/riscv32-esp-elf-gcc")))
	vim.list_extend(drivers, glob_matches(vim.fn.expand("~/.espressif/tools/riscv32-esp-elf/*/riscv32-esp-elf/bin/riscv32-esp-elf-g++")))
	vim.list_extend(drivers, glob_matches(vim.fn.expand("~/.espressif/tools/xtensa-esp-elf/*/xtensa-esp-elf/bin/xtensa-esp-elf-gcc")))
	vim.list_extend(drivers, glob_matches(vim.fn.expand("~/.espressif/tools/xtensa-esp-elf/*/xtensa-esp-elf/bin/xtensa-esp-elf-g++")))

	resolved.esp_drivers = dedupe(drivers)
	return resolved.esp_drivers
end

local function esp_cmd(root_dir)
	local clangd_path = esp_clangd_path()

	if not clangd_path then
		vim.notify_once(
			"ESP-IDF project detected but esp-clangd was not found. Falling back to Mason clangd.",
			vim.log.levels.WARN
		)
		return default_cmd()
	end

	local cmd = shared_cmd(clangd_path)
	table.insert(cmd, "--compile-commands-dir=build")

	local drivers = esp_toolchain_drivers()
	if #drivers > 0 then
		table.insert(cmd, "--query-driver=" .. table.concat(drivers, ","))
	end

	if root_dir and root_dir ~= "" and root_dir ~= "." and not vim.uv.fs_stat(vim.fs.joinpath(root_dir, "build", "compile_commands.json")) then
		vim.notify_once(
			"ESP-IDF project detected without build/compile_commands.json. Run idf.py reconfigure for better clangd results.",
			vim.log.levels.WARN
		)
	end

	return cmd
end

function M.is_esp_root(root_dir)
	if not root_dir or root_dir == "" then
		return false
	end

	for _, marker in ipairs(esp_root_markers) do
		if vim.uv.fs_stat(vim.fs.joinpath(root_dir, marker)) then
			return true
		end
	end

	return false
end

function M.find_project_root(fname)
	return util.root_pattern(unpack_fn(project_root_markers))(fname)
end

function M.esp_root_dir(bufnr, on_dir)
	local filename = normalize_bufname(bufnr)
	if not filename then
		return
	end

	local root_dir = M.find_project_root(filename)
	if root_dir and M.is_esp_root(root_dir) then
		on_dir(root_dir)
	end
end

function M.normal_root_dir(bufnr, on_dir)
	local filename = normalize_bufname(bufnr)
	if not filename then
		return
	end

	local root_dir = M.find_project_root(filename)
	if root_dir then
		if not M.is_esp_root(root_dir) then
			on_dir(root_dir)
		end
		return
	end

	-- Keep standalone C/C++ files working outside a detected workspace.
	on_dir(vim.fs.dirname(filename))
end

function M.server_configs(base_clangd)
	local esp_clangd = vim.deepcopy(base_clangd or {})
	esp_clangd.cmd = esp_cmd(".")
	esp_clangd.root_dir = M.esp_root_dir

	return {
		clangd = {
			cmd = default_cmd(),
			root_dir = M.normal_root_dir,
		},
		esp_clangd = esp_clangd,
	}
end

function M.on_attach(client, bufnr)
	if not client then
		return
	end

	if client.name ~= "clangd" and client.name ~= "esp_clangd" then
		return
	end

	-- Keep C/C++ formatting pinned to clangd so Conform can stay generic.
	vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = format_group,
		buffer = bufnr,
		desc = "Format C-family buffers with clangd before save",
		callback = function(args)
			vim.lsp.buf.format({
				async = false,
				bufnr = args.buf,
				filter = function(format_client)
					return format_client.name == "clangd" or format_client.name == "esp_clangd"
				end,
			})
		end,
	})

	local style_file = find_style_file(bufnr)
	local style = style_file and read_style_file(style_file) or {}
	local indent_width = style.indent_width or 2
	local tab_width = style.tab_width or indent_width

	-- Mirror project style locally so manual edits match clang-format output.
	vim.bo[bufnr].tabstop = tab_width
	vim.bo[bufnr].shiftwidth = indent_width
	vim.bo[bufnr].softtabstop = indent_width

	if style.use_tab == "Never" then
		vim.bo[bufnr].expandtab = true
	elseif style.use_tab == "Always" then
		vim.bo[bufnr].expandtab = false
	end
end

return M
