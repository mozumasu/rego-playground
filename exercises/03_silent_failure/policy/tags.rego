package mian

import rego.v1

# deprecated タグが付いたままの構成を止める
deny contains msg if {
	some tag in input.tags
	tag == "deprecated"
	msg := "deprecated タグが付いています。タグを外してください"
}
