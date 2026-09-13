# 02. 「キーが無い」は黙って通る — undefined と not

## 4 段で覚える

1. キーが無い → その式は `false` ではなく **undefined**
2. undefined を含むルールは**黙って不成立** → deny が出ない → conftest は緑
3. だから条件ごとに「キーが無かったら通す? 弾く?」を決める
4. **弾きたい**条件は `not x == 値` で書く。`not` は undefined でも真になる

```rego
# 事故る: tags が無いと != が undefined → ルールごと黙る
deny contains "env が prod ではない" if {
	input.tags.env != "prod"
}

# 防げる: not は undefined でも真
deny contains "env が prod ではない" if {
	not input.tags.env == "prod"
}
```

| input の tags | `!=` | `not ==` |
| --- | --- | --- |
| `env: dev` | deny | deny |
| `env: prod` | 通る | 通る |
| tags 自体が無い | **通る (事故)** | deny |

`not` を常に付けるという話ではない。`input.debug == true` で deny する条件は、
`debug` が無い入力を通して正しい。欠落を弾きたい条件だけ書き方を変える。

## 同名ルールを複数書くと OR

```rego
deny contains "owner は必須" if { not input.tags.owner }
deny contains "owner は必須" if { input.tags.owner == "" }
```

どちらか一方が成り立てば msg が deny に入る。「無い」と「空」を別のルールにすると読みやすい。

## 課題

`policy/main.rego` を直す:

1. TODO(1) は事故る版が書いてある。`tags` が無い input でも deny が出るように `not ... ==` の形に直す
2. TODO(2) `tags.owner` が無い、または空文字なら deny (メッセージ: `"owner は必須"`)。
   同名ルールを 2 本書いて OR にする

## 実行

```bash
conftest verify -p policy/
```

直す前に走らせると `test_missing_tags_denied` が落ちる。これが「キー欠落で黙る」を検出する唯一のテスト。
