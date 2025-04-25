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

  -- UI enhancements
  { "nvim-lualine/lualine.nvim" },
  { "akinsho/bufferline.nvim" },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
})

-- Basic settings
vim.o.mouse = "a"                      -- Enable mouse
vim.o.number = true                   -- Line numbers
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.cmd[[colorscheme tokyonight]]    -- Set theme

-- Nvim-tree setup
require("nvim-tree").setup()
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

-- Mason setup
require("mason").setup()

-- LSP setup
local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({}) -- Example: Lua language server

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

-- Lualine setup
require("lualine").setup()

-- Bufferline setup
require("bufferline").setup{}

-- Telescope setup
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

-- Auto-open NvimTree on startup
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