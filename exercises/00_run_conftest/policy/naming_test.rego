package naming

import rego.v1

test_underscore_denied if {
	count(deny) == 1 with input as {"name": "my_app"}
}
