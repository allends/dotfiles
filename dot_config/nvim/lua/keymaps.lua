-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Moving foward and backward inline
vim.keymap.set({'n', 'v'}, 'gl', '$')
vim.keymap.set({'n', 'v'}, 'gh', '0')

-- Moving foward and backward inline
vim.keymap.set({'n', 'v'}, 'ge', 'G')

-- Moving between buffers
vim.keymap.set({'n', 'v'}, 'gn', ':bnext<CR>')
vim.keymap.set({'n', 'v'}, 'gp', ':bprev<CR>')

-- Moving between windows
vim.keymap.set({'n', 'v'}, '<Space>w', '<C-w>')

