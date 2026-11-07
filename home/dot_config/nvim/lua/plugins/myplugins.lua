return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        position = "inline",
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local original = require("lint").linters["markdownlint-cli2"]
      local original_parser = original.parser
      original.parser = function(output, bufnr, linter_cwd)
        local diags = original_parser(output, bufnr, linter_cwd)
        return vim.tbl_filter(function(d)
          return not d.message:find("MD013")
        end, diags)
      end
      return opts
    end,
  },
}
