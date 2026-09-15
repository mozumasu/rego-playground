# 09. テストを書く — 規律は「コードパスごとに 1 件、最小 3 ケース」

08 章のポリシー (`main.rego` / `exceptions.rego`) に、スライド「テストの規律」のテストを付けて置いてある。
`policy/main_test.rego` を読んでから走らせる。

## 1. 走らせる

```bash
conftest verify -p policy/
```

```text
6 tests, 6 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

## 2. 何を固定しているか

コードパスごとに 1 件。網羅はしない (境界値のバリエーションや対称ケースは同じコードパスの別入力)。

1. **準拠入力が pass** — 正しいものを止めていない
2. **違反入力が deny** — ポリシーが生きている。壊れても緑になる言語なので、これが唯一の検出器
3. **欠落 / 対象外入力** — `environments/` の外のファイルで deny が出ない

件数は `count(deny) == N` の完全一致。`> 0` は別ルールの誤発火を見逃す。

finding 方式ならさらに 2 点:

- **rule 識別子そのもの** — `{v.rule | some v in finding} == {"workspace_env_match"}`
- **allowlist に載せたら deny が消える** — `with data.exceptions as [...]` で YAML を渡さずに免除を注入する

`with input as` と同じ要領で `with data.exceptions as` も差し替えられる。ファイルを用意せずにテストが書ける。

## Q1. rule 識別子をタイポすると?

`policy/main.rego` の `"rule": "workspace_env_match"` を `"workspace_env_mach"` にして再実行:

```text
FAIL - policy/main_test.rego -  - data.hcl.test_rule_id
FAIL - policy/main_test.rego -  - data.hcl.test_excepted

6 tests, 4 passed, 0 warnings, 2 failures, 0 exceptions, 0 skipped
```

<details><summary>答え</summary>

ポリシー自体は動いていて deny も出るので、`test_rule_id` が無ければこの typo は
「allowlist に載せたのに免除されない」という形でしか露見しない。確認したら戻す。

</details>

## Q2. workspace_separator のテストを 1 本足そう

`main.rego` の 2 本目の finding (`_` 区切りを弾く) には、まだテストが無い。
`policy/main_test.rego` に「違反入力が deny」の 1 本を足して `7 tests, 7 passed` にする。

<details><summary>答え</summary>

```rego
test_separator_denied if {
	count(deny) == 1 with input as tf("environments/staging/a.tf", "myapp_staging")
}
```

`tf(path, name)` は上で定義済み。`myapp_staging` は env (`staging`) を含むので 1 本目の finding は出ず、`_` 区切りの 1 件だけ deny になる。

</details>
