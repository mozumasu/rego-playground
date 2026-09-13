package main

import rego.v1

denny contains msg if {
	input.color == "red"
	msg := "red は禁止です"
}
