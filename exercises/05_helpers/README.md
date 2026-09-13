# 05. ヘルパー関数と組み込み関数

## 関数定義

引数を取るヘルパーが書ける。ルールと同じく、条件を満たさなければ undefined。

```rego
is_prod(env) if env == "production"

cidr_prefix(cidr) := to_number(p) if {
	[_, p] := split(cidr, "/")   # 分割代入。_ は「使わない」
}
```

## よく使う組み込み関数

| 関数 | 例 |
| --- | --- |
| `split(s, sep)` | `split("10.0.0.0/16", "/")` → `["10.0.0.0", "16"]` |
| `sprintf(fmt, [args])` | `sprintf("%s は %d 以上", ["replicas", 1])` |
| `startswith` / `endswith` / `contains` | `endswith(image, ":latest")` |
| `to_number(s)` | `to_number("16")` → `16` |
| `net.cidr_contains(range, cidr)` | `net.cidr_contains("10.0.0.0/12", "10.3.0.0/16")` → true |
| `object.get(obj, key, default)` | キーが無くても undefined にならず default を返す |

組み込み関数一覧: <https://www.openpolicyagent.org/docs/latest/policy-reference/#built-in-functions>

## 課題

VPC CIDR の検証ヘルパーを作る (07 章の布石)。実装せよ:

1. `prefix_length(cidr)` — `"10.0.0.0/16"` から数値 `16` を返す関数
2. `cidr_allowed(cidr)` — 次を両方満たすとき true:
   - `prefix_length(cidr) == 16`
   - `"10.0.0.0/12"` または `"172.16.0.0/12"` に含まれる (`net.cidr_contains`)
   - ヒント: 許可レンジは `allowed_ranges := {"10.0.0.0/12", "172.16.0.0/12"}` の set にして
     `some range in allowed_ranges` で探索
3. `input.vpc_cidr` が `cidr_allowed` でなければ deny
   (メッセージ: `sprintf("VPC CIDR %s は割当標準外", [input.vpc_cidr])`)

## 実行

```bash
conftest verify -p policy/
```

REPL で関数を単体で試すのも便利:

```bash
opa run policy/main.rego
> data.main.prefix_length("10.0.0.0/16")
```
