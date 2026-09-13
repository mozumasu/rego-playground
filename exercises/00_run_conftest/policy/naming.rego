package naming

import rego.v1

deny contains msg if {
	contains(input.name, "_")
	msg := "名前に _ は使えない"
}
