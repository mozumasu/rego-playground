package main

import rego.v1

deny contains msg if {
	input.colour == "red"
	msg := "red は禁止です"
}
