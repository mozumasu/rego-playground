package hcl

import rego.v1

import data.lib.levels

# deny / warn を書くのはここだけ。finding を 1 件ずつ allowlist (--data で渡した data.exceptions) と突合し、
# 免除でなければ rule の level で deny / warn に振り分ける (disabled は出さない)

deny contains v.msg if {
	some v in finding
	not excepted(v.path, v.rule)
	levels.level(v.rule) == "deny"
}

warn contains v.msg if {
	some v in finding
	not excepted(v.path, v.rule)
	levels.level(v.rule) == "warn"
}

# ファイル単位の免除。reason が空なら免除しない
excepted(path, rule) if {
	some e in data.exceptions
	e.path == path
	e.rule == rule
	trim_space(e.reason) != ""
}
