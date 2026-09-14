package main

import rego.v1

# TODO(1): 事故る版。tags が無い input では != が undefined になり、このルールは黙る。
# not ... == の形に直して、tags が無くても deny が出るようにする
deny contains "env が prod ではない" if {
	input.tags.env != "prod"
}

# TODO(2): tags.owner が無い、または空文字なら deny ("owner は必須")
# ヒント: 同名ルールを 2 本書くと OR になる。「無い」は not、「空」は == "" で見る
deny contains "owner は必須" if {
	false # ここを実装する (この行は消す)
}
