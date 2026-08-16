local M = {}

function M.map(mode, lhs, rhs, desc, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

function M.buffer_map(bufnr, mode, lhs, rhs, desc, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { buffer = bufnr, desc = desc }, opts or {}))
end

return M
