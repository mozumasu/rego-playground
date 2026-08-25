package main

import rego.v1

default allow := false

# TODO(1): input.role が "admin" なら allow を true にするルールを追加する

# TODO(2): input.owner が無ければ deny ("owner は必須")
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}

# TODO(3): tier が "free" でも "paid" でもなければ deny ("tier は free か paid")
# ヒント: valid_tier ルールを 2 本書いて OR を作り、not valid_tier で否定する
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
