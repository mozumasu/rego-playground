package main

import rego.v1

# --- 検出器。ここは編集しない ---

test_red_denied if {
	count(deny) == 1 with input as {"color": "red"}
}
