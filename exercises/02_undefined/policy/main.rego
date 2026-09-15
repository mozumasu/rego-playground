package main

import rego.v1

# 防げる: not は undefined でも真
deny contains "env が prod ではない" if {
	not input.tags.env == "prod"
}
