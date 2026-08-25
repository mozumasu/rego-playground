# 02. undefined と default — Rego 最大の特徴

## ルールは「関数」ではなく「クエリ」

Rego のルールは true / false を返す関数ではない。条件が成立しなければ
結果は **undefined** (「何も言えない」) になる。false とは別物。

```rego
allow if input.role == "admin"
```

- `input.role == "admin"` → `allow` は `true`
- `input.role == "guest"` → `allow` は **undefined** (false ではない!)
- `input` に `role` キーが**無い** → これも undefined

undefined は「評価に失敗した」でもエラーでもなく、単に「このルールからは何も導けない」。
deny ルールが何も生まないのはこの仕組みのおかげ。

## default で undefined に既定値を与える

```rego
default allow := false

allow if input.role == "admin"
```

これで `allow` は必ず true か false になる。API の許可判定などでは必須のイディオム。

## not は「undefined なら true」

```rego
deny contains "owner がいない" if {
	not input.owner
}
```

`not X` は「X が undefined または false なら成立」。
キーの欠落チェックによく使うが、**「キーがあるが値が false」も引っかかる**点に注意。

## 課題

`policy/main.rego` に実装せよ:

1. `default allow := false` を宣言し、`input.role == "admin"` なら `allow` を true にする
2. `input.owner` が無い (または falsy) なら deny
   (メッセージ: `"owner は必須"`)
3. `input.tier` が `"free"` **でも** `"paid"` **でもない**なら deny
   (メッセージ: `"tier は free か paid"`)
   ヒント: 同名ルールを複数書くと OR になる。`valid_tier if ...` を 2 つ書いて `not valid_tier`

## 実行

```bash
conftest verify -p policy/
```
