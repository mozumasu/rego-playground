package lib.levels

import rego.v1

# rule の level (deny / warn / disabled) を 呼び出し側の上書き (data.rules) > ポリシー側の既定 (data.levels) > deny
# の順で決める。どちらにも無い rule は deny (fail-closed)
level(rule) := l if {
	l := data.rules[rule].level
	rank[l]
	not lowered_without_reason(rule, l)
} else := l if {
	l := data.levels[rule]
} else := "deny"

# 既定より下げるには reason が必須。無ければ上書きを無視して既定で評価する。上げるのは自由
lowered_without_reason(rule, l) if {
	rank[l] < rank[object.get(data.levels, rule, "deny")]
	trim_space(object.get(data.rules[rule], "reason", "")) == ""
}

rank := {"disabled": 0, "warn": 1, "deny": 2}
