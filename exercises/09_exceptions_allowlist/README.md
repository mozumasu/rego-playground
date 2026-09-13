# 09. 実戦: 例外 allowlist (finding → deny)

07 章のポリシーを本番のリポジトリに入れると、既存の workspace が何十件も引っかかる。
リネームは state の付け替えを伴うので、すぐには直せない。
かといって rego に例外をハードコードすると、例外が増えるたびにポリシーが汚れる。

実務では **「禁止」ではなく「理由の明示を強制」する**形にしている:

- ポリシーは `deny` を書かず、構造化した **`finding`** (`{path, rule, msg}`) を出す
- 共通の `exceptions.rego` が、リポジトリ側の allowlist (`--data` で渡す YAML) と突合し、
  免除されなかった finding だけを `deny` にする
- allowlist は `path` × `rule` の組で、`reason` が空なら無効

```yaml
# exceptions.yaml
exceptions:
  - path: environments/production/web/terraform.tf
    rule: workspace_env_match
    reason: "移行中。2026-10 のメンテナンスウィンドウでリネームする"
  - path: "*"              # rule 単位でリポジトリ全体を免除 (既存の grandfather 用)
    rule: workspace_separator
    reason: "命名規約制定前からのリポジトリ"
```

## 仕組み

`policy/exceptions.rego` (完成済み。読んで理解するだけでよい):

```rego
deny contains f.msg if {
	some f in finding
	not excepted(f.path, f.rule)
}
```

- `--data exceptions.yaml` で渡した YAML は `data.exceptions` として読める
- `--data` を付けなければ `data.exceptions` は undefined → `excepted` も undefined →
  `not excepted(...)` が真 → **全部 deny** (fail-closed)
- `rule` の typo は「一致しない」だけでエラーにならない。免除が効かないときはまず typo を疑う

この方式の利点は、ポリシー側に「免除判定の呼び忘れ」が構造的に起きないこと。
ポリシーは finding を出すだけで、deny 化は 1 箇所に集約される。

## 課題

`policy/main.rego` に実装せよ (07 章のヘルパーは完成済み):

1. `finding` その 1 — 07 章の deny を finding に書き換える。
   `{"path": doc.path, "rule": "workspace_env_match", "msg": ...}` (msg は 07 と同じ)
2. `finding` その 2 — workspace 名に `-` が無く `_` があれば
   `{"path": doc.path, "rule": "workspace_separator", "msg": sprintf("%s: workspace 名 %q は `_` 区切り。`-` を使うこと", [doc.path, name])}`

`main.rego` に `deny` を書いてはいけない (書くと allowlist を素通りする)。

## 実行

```bash
conftest verify -p policy/                                                    # 採点

# allowlist なし → production/web と staging/legacy の 2 件が FAIL
conftest test -p policy/ --parser hcl2 --combine $(find terraform -name '*.tf')

# allowlist あり → 両方免除されて pass
conftest test -p policy/ --parser hcl2 --combine --data exceptions.yaml $(find terraform -name '*.tf')
```

`exceptions.yaml` の `reason` を空文字にして、免除が無効になることも確かめてみるとよい。
