package main

import rego.v1

# 事故る: tags が無いと != が undefined → ルールごと黙る
deny contains "env が prod ではない" if {
	input.tags.env != "prod"
}
