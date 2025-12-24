-- Install lazy.nvim plugin manager if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
-- Plugin setup
require("lazy").setup({
  -- File explorer
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },

  -- Theme
  { "folke/tokyonight.nvim" },

  -- LSP and Completion
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "L3MON4D3/LuaSnip" },
  { "neovim/nvim-lspconfig" },
  "mfussenegger/nvim-dap",
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
  },
  { "rcarriga/nvim-dap-ui" },

  -- UI enhancements
  { "nvim-lualine/lualine.nvim" },
  { "akinsho/bufferline.nvim" },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  {
  "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      "sindrets/diffview.nvim",        -- optional - Diff integration

      "nvim-telescope/telescope.nvim", 
    },
    cmd = "Neogit",
    keys = {
      { "M-g", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
    }
  }
})

-- Basic settings
vim.o.mouse = "a"
vim.opt.virtualedit = "onemore"
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.cmd[[colorscheme tokyonight]]
--Tabs
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

require("mason").setup()
require("lualine").setup()
require("bufferline").setup()
local builtin = require("telescope.builtin")

-- Key maps
vim.keymap.set("n", "<M-f>", builtin.live_grep, {})
vim.keymap.set("n", "<M-q>", ":bdelete<CR>")
vim.keymap.set("n", "<M-g>", ":Neogit<CR>")

-- Nvim-tree setup
require("nvim-tree").setup()
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
local function open_nvim_tree_on_startup(data)
  -- skip when opening a file directly or in diff mode
  local real_file = vim.fn.filereadable(data.file) == 1
  local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
  if not real_file and not no_name then
    return
  end

  require("nvim-tree.api").tree.open()
end
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree_on_startup })

-- Completion setup
local cmp = require("cmp")
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = {
    { name = 'nvim_lsp' },
  },
})

-- LSP setup
local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({}) -- Example: Lua language server

-- C# stuff
local dap, dapui = require("dap"), require("dapui")
dapui.setup({
  layouts = {
    {
      elements = {
        "scopes",
        "breakpoints",
        "stacks",
        "watches",
      },
      size = 40,   -- width in columns
      position = "right",  -- left, right, top, bottom
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 5,  -- height in lines
      position = "bottom",
    },
  },
})
dap.adapters.coreclr = {
  type = 'executable',
  command = vim.fn.exepath('netcoredbg'),
  args = { '--interpreter=vscode' },
}
dap.configurations.cs = {
  {
    type = 'coreclr',
    name = 'Launch .NET App',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/', 'file')
    end,
  },
}

-- Toggle breakpoint on current line
vim.keymap.set('n', '<F9>', dap.toggle_breakpoint, {})

-- Conditional breakpoint
vim.keymap.set('n', '<M-F9>', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, {})

-- Start debugging
vim.keymap.set('n', '<F5>', dap.continue, {})

-- Step over / into / out
vim.keymap.set('n', '<F10>', dap.step_over, {})
vim.keymap.set('n', '<F11>', dap.step_into, {})
vim.keymap.set('n', '<F12>', dap.step_out, {})

-- Open DAP UI
vim.keymap.set('n', '<F4>', dapui.toggle, {})
-- /C# stuff
