package main

import rego.v1

# TODO(1): どのサービスでも ports に 1024 未満があれば deny
# msg は sprintf("%s: 特権ポート %d は禁止", [name, port])
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}

# TODO(2): 全サービスの replicas が 2 以上なら成立するように書き換える (every を使う)
ha_ready if {
	false # 仮実装。正しく実装する
}

# TODO(3): ha_ready でなければ deny ("全サービス replicas 2 以上が必要")
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
