package main        # 必須。1 ファイルに 1 つ

import rego.v1      # Rego のバージョンを指定

warn contains msg if {
	is_big
	msg := "size 超過"
}

max_size := 10

is_big if input.size > max_size
