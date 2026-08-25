# 05. テストを書く — conftest verify

## Rego のテスト

`*_test.rego` に `test_` で始まるルールを書くと `conftest verify` が実行する。
テストルールが **成立すれば pass、undefined になれば fail**。

```rego
test_debug_denied if {
	deny["debug 禁止"] with input as {"debug": true}
}
```

- `with input as <値>` で入力を差し替える。テストの肝はこれだけ
- `deny["メッセージ"]` = 「その要素が deny 集合に**ある**」の検査
- `count(deny) == 0` = 「何も deny されない」の検査

## 何をテストするか (テスト設計の型)

1. **正常系**: 違反なしの入力で `count(deny) == 0`
2. **異常系**: 各ルールが発火する入力で `deny["..."]`
3. **境界値**: しきい値ちょうど・1 つ外れの両側
4. **相反検証**: 「発火する」だけでなく「発火**しない**」も対で書く
   (これが無いと「常に deny する」壊れ方を検出できない)

## 課題

`policy/main.rego` に完成済みのポリシーがある (編集しない):

- image が `:latest` タグ → deny
- `cpu_limit` が 4 を超える → deny

`policy/main_test.rego` の `test_` ルールの中身 (`false` の行) を実装せよ。
テスト名が仕様のヒントになっている。**全テストが pass したら合格**
(`false` を `true` に変えるだけでも通ってしまうが、それでは学びがないので
必ず `with input as` で本物の検証を書くこと)。

## 実行

```bash
conftest verify -p policy/
```
