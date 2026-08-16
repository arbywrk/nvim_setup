local function confirm(message, action)
    return function(...)
        local args = { ... }

        if vim.fn.confirm(message, "&Yes\n&No", 2) ~= 1 then
            return
        end

        action(unpack(args))
    end
end

return {
    "lewis6991/gitsigns.nvim",

    event = { "BufReadPre", "BufNewFile" },

    opts = {
        ----------------------------------------------------------------------
        -- Signs
        ----------------------------------------------------------------------

        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "" },
            topdelete = { text = "" },
            changedelete = { text = "▎" },
            untracked = { text = "▎" },
        },

        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,

        ----------------------------------------------------------------------
        -- Blame
        ----------------------------------------------------------------------

        current_line_blame = false,

        current_line_blame_opts = {
            delay = 300,
            virt_text_pos = "eol",
            ignore_whitespace = true,
        },

        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",

        ----------------------------------------------------------------------
        -- Preview
        ----------------------------------------------------------------------

        preview_config = {
            border = "rounded",
            style = "minimal",
        },

        ----------------------------------------------------------------------
        -- Keymaps
        ----------------------------------------------------------------------

        on_attach = function(bufnr)
            local gs = require("gitsigns")
            local keymap = require("util.keymap")

            local function map(mode, lhs, rhs, desc)
                keymap.buffer_map(bufnr, mode, lhs, rhs, desc, { silent = true })
            end

            ------------------------------------------------------------------
            -- Navigation
            ------------------------------------------------------------------

            map("n", "]h", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                    return
                end

                gs.nav_hunk("next")
            end, "Git: Next hunk")

            map("n", "[h", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                    return
                end

                gs.nav_hunk("prev")
            end, "Git: Previous hunk")

            ------------------------------------------------------------------
            -- Stage
            ------------------------------------------------------------------

            map("n", "<leader>ghs", gs.stage_hunk, "Git: Stage hunk")

            map("v", "<leader>ghs", function()
                gs.stage_hunk({
                    vim.fn.line("."),
                    vim.fn.line("v"),
                })
            end, "Git: Stage selection")

            map("n", "<leader>ghS", confirm("Stage every change in this file?", gs.stage_buffer), "Git: Stage buffer")

            map("n", "<leader>ghu", gs.undo_stage_hunk, "Git: Undo stage")

            ------------------------------------------------------------------
            -- Reset
            ------------------------------------------------------------------

            map("n", "<leader>ghr", confirm("Discard this hunk?", gs.reset_hunk), "Git: Reset hunk")

            map("v", "<leader>ghr", function()
                if vim.fn.confirm("Discard selected lines?", "&Yes\n&No", 2) ~= 1 then
                    return
                end

                gs.reset_hunk({
                    vim.fn.line("."),
                    vim.fn.line("v"),
                })
            end, "Git: Reset selection")

            map(
                "n",
                "<leader>ghR",
                confirm("Discard ALL unstaged changes in this file?", gs.reset_buffer),
                "Git: Reset buffer"
            )

            ------------------------------------------------------------------
            -- Preview
            ------------------------------------------------------------------

            map("n", "<leader>ghp", gs.preview_hunk_inline, "Git: Preview hunk")

            ------------------------------------------------------------------
            -- Blame
            ------------------------------------------------------------------

            map("n", "<leader>ghb", gs.blame_line, "Git: Blame line")

            map("n", "<leader>ghB", function()
                gs.blame_line({
                    full = true,
                })
            end, "Git: Full blame")

            ------------------------------------------------------------------
            -- Diff
            ------------------------------------------------------------------

            map("n", "<leader>ghd", gs.diffthis, "Git: Diff against index")

            map("n", "<leader>ghD", function()
                gs.diffthis("@")
            end, "Git: Diff against HEAD")

            ------------------------------------------------------------------
            -- Toggles
            ------------------------------------------------------------------

            map("n", "<leader>ugb", gs.toggle_current_line_blame, "Toggle Git blame")

            map("n", "<leader>ugd", gs.toggle_deleted, "Toggle deleted lines")

            map("n", "<leader>ugw", gs.toggle_word_diff, "Toggle word diff")

            ------------------------------------------------------------------
            -- Text objects
            ------------------------------------------------------------------

            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git hunk")
        end,
    },
}
