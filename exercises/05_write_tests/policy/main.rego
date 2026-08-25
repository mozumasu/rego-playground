package main

import rego.v1

# --- 完成済みポリシー。ここは編集しない ---

deny contains msg if {
	endswith(input.image, ":latest")
	msg := sprintf("%s: latest タグは禁止", [input.image])
}

deny contains msg if {
	input.cpu_limit > 4
	msg := sprintf("cpu_limit %v は上限 4 を超過", [input.cpu_limit])
}
