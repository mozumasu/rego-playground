package main

import rego.v1

deny contains msg if {
	input.environment == "production"
	input.debug == true
	msg := "production では debug を無効に"
}
