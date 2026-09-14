package main

import rego.v1

# TODO(1): environment == "production" かつ debug == true なら deny
# msg は "production で debug は有効にできない"
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}

# TODO(2): replicas < 1 なら deny
# msg は "replicas は 1 以上が必要"
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
