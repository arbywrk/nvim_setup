local keymap = require("util.keymap")

keymap.map("n", "<leader>tr", function()
    require("neotest").run.run()
end, "Test: Run nearest")

keymap.map("n", "<leader>tf", function()
    require("neotest").run.run(vim.fn.expand("%"))
end, "Test: Run file")

keymap.map("n", "<leader>ts", function()
    require("neotest").summary.toggle()
end, "Test: Toggle summary")

keymap.map("n", "<leader>to", function()
    require("neotest").output.open({ enter = true })
end, "Test: Show output")

require("neotest").setup({
    adapters = {
        require("rustaceanvim.neotest"),
        require("neotest-python"),
    },
})
