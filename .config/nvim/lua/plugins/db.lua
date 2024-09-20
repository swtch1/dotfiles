-- env vars, with defaults so lua doesn't complain
local postgres_conn_string = os.getenv("POSTGRES_CONN_STRING") or ""

-- TODO: pick one of these

-- -- FIXME: this has not been configured yet, add conn string for localhost
return {
-- {
--   "kndndrj/nvim-dbee",
--   dependencies = {
--     "MunifTanjim/nui.nvim",
--   },
--   lazy = true,
--   build = function()
--     -- Install tries to automatically detect the install method.
--     -- if it fails, try calling it with one of these parameters:
--     --    "curl", "wget", "bitsadmin", "go"
--     require("dbee").install()
--   end,
--   config = function()
--     require("dbee").setup(--[[optional config]])
--   end,
-- },

-- -- FIXME: this has not been configured yet, add conn string for localhost
-- {
--   'kristijanhusak/vim-dadbod-ui',
--   dependencies = {
--     { 'tpope/vim-dadbod', lazy = true },
--     { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
--   },
--   cmd = {
--     'DBUI',
--     'DBUIToggle',
--     'DBUIAddConnection',
--     'DBUIFindBuffer',
--   },
--   init = function()
--     -- Your DBUI configuration
--     vim.g.db_ui_use_nerd_fonts = 1
--   end,
-- },
}
