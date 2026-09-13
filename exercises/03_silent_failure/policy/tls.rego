package main

import rego.v1

# TLS は必須
deny contains msg if {
	input.tls.enabld == false
	msg := "TLS が無効です。tls.enabled を true にしてください"
}
