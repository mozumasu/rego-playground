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

## 課題

`policy/main.rego` の 2 つの `finding` に `# METADATA` を書け:

1. `title` は rule 識別子と**同じ文字列** (`workspace_env_match` / `workspace_separator`)
2. `description` は 1 文で
3. `custom.source` に根拠 (issue 番号や規約へのリンク)

この章の採点はテストではなく生成結果で行う:

```bash
mkdir -p out && conftest doc -t table.tmpl policy/ -o out/ && cat out/policy.md
```

2 行の表が出て、`<no value>` が無ければ合格。
注釈が 1 つも無いうちは `no annotations found` で止まり、`custom.source` を書き忘れるとそのセルが `<no value>` になる。

## 実務での運用

実務では、生成した表を `policy/README.md` のマーカー間に埋め込み、
CI で `--check` (再生成して diff) することで「注釈を書き忘れた」「README が古い」を落としている。
あわせて、注釈の `title` と `finding` が出す `"rule"` の集合が一致することも検査する。
