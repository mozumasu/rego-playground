# 10. METADATA 注釈とドキュメント生成

ポリシーが増えると「どの rule 識別子が何を検査するか」の一覧が要る。
allowlist に書く `rule` の typo は黙って免除されないだけなので、正しい識別子を引ける表が無いと運用できない。
手で書くと必ずずれるので、**rego の注釈から生成する**。

## `# METADATA` 注釈

OPA 標準の仕組み。`# METADATA` で始まるコメントブロックを YAML として読み、
直後のルールに紐付ける (これが rule スコープ)。

```rego
# METADATA
# title: workspace_env_match
# description: "`environments/<env>/` の env セグメントが workspace 名に含まれること"
# custom:
#   source: "docs/naming.md (workspace 命名規約)"
finding contains v if {
	...
}
```

- `title` / `description` は標準フィールド。`custom:` の下は自由
- YAML なので、バッククォートで始まる値は引用符で囲む
- **package スコープ** (`package` 行の直前) もあるが、パッケージに 1 つしか置けない。
  複数ファイルで 1 つのパッケージを共有する構成では rule スコープを使う

## 生成する

`conftest doc` が注釈を集め、Go template で整形する:

```bash
mkdir -p out && conftest doc -t table.tmpl policy/ -o out/
cat out/policy.md
```

`table.tmpl`:

```text
| rule 識別子 | 内容 | 根拠 |
| --- | --- | --- |
{{ range . -}}
| `{{ .Annotations.Title }}` | {{ .Annotations.Description }} | {{ index .Annotations.Custom "source" }} |
{{ end -}}
```

テンプレートに渡るのは `[]Section{RegoPackageName, Annotations}` の配列。
`.Annotations.Title` / `.Description` / `.Custom` / `.Location.File` が使える。

## 生成してみる

`policy/main.rego` の 2 つの `finding` に `# METADATA` が付けてある (スライド「METADATA 注釈でポリシー一覧を自動生成」と同じ)。

```bash
mkdir -p out && conftest doc -t table.tmpl policy/ -o out/ && cat out/policy.md
```

```text
| rule 識別子 | 内容 | 根拠 |
| --- | --- | --- |
| `workspace_env_match` | environments/<env>/ の env が workspace 名に含まれること | 社内の workspace 命名規約 |
| `workspace_separator` | workspace 名の区切りは - を使い、_ を使わないこと | 社内の workspace 命名規約 |
```

`title` は `finding` が出す `"rule"` と同じ文字列にしてある。08 章の allowlist に書く `rule` は、この表から写す。

## Q1. source を消すと?

1 つ目の `# METADATA` から `custom:` と `source:` の 2 行を消して再生成する。

<details><summary>答え</summary>

```text
| `workspace_env_match` | environments/<env>/ の env が workspace 名に含まれること | <no value> |
```

そのセルが `<no value>` になる。実務では CI で `<no value>` を grep して落とす。確認したら戻す。

</details>

## Q2. package スコープに書くと?

`main.rego` と `exceptions.rego` の両方で、`package hcl` の直前に `# METADATA` / `# title: hcl` を書いて再生成する。

<details><summary>答え</summary>

```text
Error: ... rego_type_error: package annotation redeclared
```

package スコープの注釈は package に 1 つしか置けない。複数ファイルで `package hcl` を共有しているので、rule スコープ (rule の直前) に書く。確認したら戻す。

</details>

## 実務での運用

生成した表を `policy/README.md` のマーカー間に埋め込み、CI で再生成して diff することで
「注釈を書き忘れた」「README が古い」を落としている。あわせて、注釈の `title` と `finding` が出す `"rule"` の集合が一致することも検査する。
