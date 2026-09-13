package main

import rego.v1

# --- 共通基盤。ここは編集しない ---
#
# 各ポリシーは deny を直接書かず finding {path, rule, msg} を出す。
# allowlist (--data で渡す data.exceptions) と突合し、免除されない finding だけをここで deny にする。
# deny を定義してよいのはこのファイルだけ。

valid_reason(e) if {
	is_string(e.reason)
	trim_space(e.reason) != ""
}

# ファイル単位の免除
excepted(path, rule) if {
	some e in data.exceptions
	e.rule == rule
	e.path == path
	valid_reason(e)
}

# path: "*" は rule 単位でリポジトリ全体を免除する (既存リポジトリの grandfather 用)
excepted(_, rule) if {
	some e in data.exceptions
	e.rule == rule
	e.path == "*"
	valid_reason(e)
}

deny contains f.msg if {
	some f in finding
	not excepted(f.path, f.rule)
}
