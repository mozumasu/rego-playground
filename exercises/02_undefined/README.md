# 02. 「キーが無い」は黙って通る — undefined と not

スライド「キーが無い」の 2 つのルールをそのまま置いてある。書き換えずに、
`tags` の無い input を渡して deny がどうなるかを見る。

用意してあるファイル:

- `input.json` — `tags` が無い input (`{ "name": "app" }`)
- `dev.json` — `tags.env` が `dev` の input
- `policy_bug/main.rego` — 事故る版。`input.tags.env != "prod"`
- `policy/main.rego` — 防げる版。`not input.tags.env == "prod"`

## 1. 事故る版に tags 無しの input を渡す

```bash
conftest test -p policy_bug/ input.json
```

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
```

env が prod ではないのに通る。理由を opa eval で見る:

```bash
opa eval -d policy_bug/ -i input.json 'input.tags.env != "prod"' -f pretty
```

```text
undefined
```

1. キーが無い → その式は `false` ではなく **undefined**
2. undefined を含むルールは**黙って不成立** → deny が出ない → conftest は緑

`dev.json` (env が dev) なら事故る版でも deny が出る。事故るのは「キーが無い」ときだけ。

## 2. 防げる版に同じ input を渡す

```bash
conftest test -p policy/ input.json
```

```text
FAIL - input.json - main - env が prod ではない

1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

`not` は undefined でも真になるので、キーが無い input を弾ける。

| input の tags | `!=` | `not ==` |
| --- | --- | --- |
| `env: dev` | deny | deny |
| `env: prod` | 通る | 通る |
| tags 自体が無い | **通る (事故)** | deny |

## 3. 決めるのは「キーが無かったら通す? 弾く?」

`not` を常に付けるという話ではない。`input.debug == true` で deny する条件は、
`debug` が無い入力を通して正しい。弾きたい条件だけ `not x == 値` の形で書く。

## Q1. 両方とも通るようにしよう

`input.json` だけを書き換えて、`policy_bug/` と `policy/` の両方で `1 test, 1 passed` にする。

<details><summary>答え</summary>

`"tags": { "env": "prod" }` を足す。値があれば `!=` も `not ==` も同じ判定になる。差が出るのはキーが無いときだけ。

</details>

## Q2. 事故る版を直そう

`policy_bug/main.rego` を 1 行直して、`tags` の無い `input.json` でも deny が出るようにする。

<details><summary>答え</summary>

```rego
	not input.tags.env == "prod"
```

`!=` を `not ==` に。`policy/main.rego` と同じ形になる。

</details>
