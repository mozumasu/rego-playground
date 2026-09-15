# 04. ヘルパー関数と組み込み関数

スライド「ヘルパー関数 (自作) と組み込み関数」の `policy/cidr.rego` をそのまま置いてある。
deny の条件を `cidr_allowed(cidr)` に切り出して名前を付けたもの。

用意してあるファイル:

- `ok.json` — `10.1.0.0/16` (割当内)
- `ng.json` — `192.168.0.0/16` (割当外)
- `empty.json` — `cidr` キーが無い

## 1. 3 つの input を通す

```bash
conftest test -p policy/ ok.json
conftest test -p policy/ ng.json
conftest test -p policy/ empty.json
```

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
FAIL - ng.json - main - CIDR 192.168.0.0/16 は割当外です
FAIL - empty.json - main - CIDR null は割当外です
```

`empty.json` も deny になるのは、`object.get(input, ["cidr"], null)` が欠落を `null` に変えてから
`not cidr_allowed(null)` を評価するから。02 章の「キーが無いと黙る」を避ける書き方。

## 2. ヘルパー関数を単体で呼ぶ

```bash
opa eval -d policy/ 'data.main.cidr_allowed("10.1.0.0/16")' -f pretty   # true
opa eval -d policy/ 'data.main.cidr_allowed("10.1.0.0/24")' -f pretty   # undefined (/16 ではない)
```

関数もルールなので、条件を満たさなければ `false` ではなく undefined。

## Q1. ng.json を通るようにしよう

`ng.json` の CIDR だけを書き換えて `conftest test -p policy/ ng.json` を通す。

<details><summary>答え</summary>

`10.0.0.0/12` か `172.16.0.0/12` に含まれる /16 にする。`10.1.0.0/16` でも `172.16.5.0/16` でもよい。
`allowed` の 2 レンジのどちらかに `net.cidr_contains` で入り、かつ prefix が 16 なら `cidr_allowed` が真になる。

</details>

## Q2. /24 も通るようにしよう

`{ "cidr": "10.1.0.0/24" }` は今は deny になる。`policy/cidr.rego` を 1 行だけ直して、/16 と /24 の両方を通す。

<details><summary>答え</summary>

```rego
	to_number(split(cidr, "/")[1]) in {16, 24}
```

`== 16` を集合への `in` にする。`>= 16` でもよいが、/32 まで通ることになる。
直したあとも `ng.json` (192.168.0.0/16) は deny のまま。

</details>

## おまけ: 組み込み関数を 1 段ずつ見る

```bash
opa eval 'split("10.1.0.0/16", "/")' -f pretty          # ["10.1.0.0", "16"]
opa eval 'to_number(split("10.1.0.0/16", "/")[1])' -f pretty   # 16
opa eval 'net.cidr_contains("10.0.0.0/12", "10.1.0.0/16")' -f pretty   # true
```

| 関数 | 用途 |
| --- | --- |
| `split(s, "/")` | 分割 |
| `sprintf("%v", [x])` | 整形 |
| `net.cidr_contains(a, b)` | CIDR 包含 |
| `object.get(o, [k], def)` | 欠落時の既定値 |

一覧: <https://www.openpolicyagent.org/docs/latest/policy-reference/#built-in-functions>
