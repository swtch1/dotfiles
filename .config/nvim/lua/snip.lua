local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local fmt = require("luasnip.extras.fmt").fmt
local m = require("luasnip.extras").m
local lambda = require("luasnip.extras").l
local postfix = require("luasnip.extras.postfix").postfix

ls.add_snippets("go", {
        -- s("ife", {
		-- t({"if err != nil {", "return fmt.Errorf(err)", "}"}, i(0)),
	-- }),
	postfix(".debug", {
                d(1, function(_, parent)
                      return sn(nil, {
			      t('fmt.Printf(" -> JMTDEBUG: %s: %+v\\n", "' .. parent.snippet.env.POSTFIX_MATCH), i(1), t('", '  .. parent.snippet.env.POSTFIX_MATCH), t(') // FIXME: (JMT) testing')
		      })
                end),
	}),
})

