package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

base := {"role": "admin", "owner": "sre-team", "tier": "paid"}

test_admin_allowed if {
	allow with input as base
}

test_guest_not_allowed if {
	not allow with input as object.union(base, {"role": "guest"})
}

# allow は default があるので undefined ではなく false になるはず
test_allow_is_false_not_undefined if {
	allow == false with input as object.union(base, {"role": "guest"})
}

test_missing_owner_denied if {
	deny["owner は必須"] with input as {"role": "admin", "tier": "free"}
}

test_owner_present_allowed if {
	count(deny) == 0 with input as base
}

test_invalid_tier_denied if {
	deny["tier は free か paid"] with input as object.union(base, {"tier": "enterprise"})
}

test_free_tier_allowed if {
	count(deny) == 0 with input as object.union(base, {"tier": "free"})
}

test_missing_tier_denied if {
	deny["tier は free か paid"] with input as {"role": "admin", "owner": "sre-team"}
}
