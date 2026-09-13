package mian

import rego.v1

deny contains msg if {
	input.color == "red"
	msg := "red は禁止です"
}
