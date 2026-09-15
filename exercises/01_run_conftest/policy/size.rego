package main

max_size := 10

is_big if input.size > max_size

deny contains msg if {
	is_big
	msg := "size 超過"
}
