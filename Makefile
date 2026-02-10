.PHONY: all lint format check typecheck

all: typecheck lint format

lint:
	luacheck .

format:
	stylua .

typecheck:
	lua-language-server --check . --checklevel=Warning --metapath /tmp/lua-language-server-meta --logpath /tmp/lua-language-server-log

check: typecheck lint
	stylua --check .
