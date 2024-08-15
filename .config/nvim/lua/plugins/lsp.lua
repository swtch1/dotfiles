return {
  {
    'williamboman/mason.nvim',
    opts = {
      ui = {
	icons = {
	  package_installed = '✓',
	  package_pending = '➜',
	  package_uninstalled = '✗',
	},
      },
    },
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      'williamboman/mason.nvim',
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'SmiteshP/nvim-navic',
      'williamboman/mason.nvim',
    },
  },
  { 'hrsh7th/nvim-cmp', },
  { 'hrsh7th/cmp-nvim-lsp', },
  { 'hrsh7th/cmp-buffer', },
  { 'hrsh7th/cmp-path', },
  {
    'hrsh7th/cmp-nvim-lua',
    lazy = true,
    ft = { 'lua' },
  },
  { 'mfussenegger/nvim-jdtls' },
  {
    'SmiteshP/nvim-navic',
    opts = {
      icons = {
        File          = "",
        Module        = "",
        Namespace     = "",
        Package       = "",
        Class         = "",
        Method        = "",
        Property      = "",
        Field         = "",
        Constructor   = "",
        Enum          = "",
        Interface     = "",
        Function      = "",
        Variable      = "",
        Constant      = "",
        String        = "",
        Number        = "",
        Boolean       = "",
        Array         = "",
        Object        = "",
        Key           = "",
        Null          = "",
        EnumMember    = "",
        Struct        = "",
        Event         = "",
        Operator      = "",
        TypeParameter = "",
      },
      separator = ' > ',
    },
  },
}
