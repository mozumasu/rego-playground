package hcl

import rego.v1

# deny を書くのはここだけ。finding を 1 件ずつ allowlist (--data で渡した data.exceptions) と突合し、
# 免除でなければ deny にする

deny contains v.msg if {
	some v in finding
	not excepted(v.path, v.rule)
}

# ファイル単位の免除。reason が空なら免除しない
excepted(path, rule) if {
	some e in data.exceptions
	e.path == path
	e.rule == rule
	trim_space(e.reason) != ""
}

# path: "*" は rule 単位で全ファイルを免除する (既存リポジトリの grandfather 用)
excepted(_, rule) if {
	some e in data.exceptions
	e.path == "*"
	e.rule == rule
	trim_space(e.reason) != ""
}
