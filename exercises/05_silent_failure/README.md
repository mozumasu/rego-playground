# 05. 壊しても静か — silent pass とテストという検出器

02 で見たとおり、条件が成立しなければ結果は undefined になる。エラーではない。
この性質には裏がある。**タイポでポリシーが死んでいても、CI は「違反ゼロ」と同じ顔で緑になる**。

普通の言語なら例外や未定義エラーになる 3 パターンを、実際に走らせて確認する。

## 実験

`experiments/` に、同じポリシーの正しい版と壊した版が置いてある。

```rego
deny contains msg if {
	input.color == "red"
	msg := "red は禁止です"
}
```

入力は `experiments/input.json` の `{"color": "red"}`。本来は必ず deny が出る。

### 00. まず正しい版

```bash
cd exercises/05_silent_failure
conftest test -p experiments/00_correct experiments/input.json
```

```text
FAIL - experiments/input.json - main - red は禁止です
1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

### 実験 1: フィールド名のタイポ

`input.color` を `input.colour` にしただけ (`experiments/01_field_typo/main.rego`)。

```bash
conftest test -p experiments/01_field_typo experiments/input.json
```

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
```

red なのに **pass する**。`input.colour` は存在しないので undefined になり、
ルールが不成立になり、deny が空になり、合格になる。エラーは 1 行も出ない。

### 実験 2: ルール名のタイポ

`deny` を `denny` にしただけ (`experiments/02_rule_name_typo/main.rego`)。

```bash
conftest test -p experiments/02_rule_name_typo experiments/input.json
```

```text
0 tests, 0 passed, 0 warnings, 0 failures, 0 exceptions
```

conftest は `deny` / `violation` / `warn` という名前のルールしか見ない。
`denny` は無視され「テスト 0 件で合格」になる。
`0 tests` は手掛かりになるが、CI の緑チェックにその数字は出ない。

### 実験 3: package 名のタイポ

`package main` を `package mian` にしただけ (`experiments/03_package_typo/main.rego`)。
実験 2 と同じく `0 tests` で pass する。
conftest は既定で namespace `main` だけを評価するので、別の package は存在しないのと同じ扱いになる。

### 静的チェックでは捕まらない

```bash
opa check --strict experiments/01_field_typo   # 何も言わずに終了コード 0
opa eval -i experiments/input.json 'input.colour'   # undefined
```

`opa check --strict` は未使用変数などは検出する。
だが input のフィールド名は input を見るまで正しいか分からないので検出できない。

### 唯一の検出器: deny が発火するテスト

`experiments/detector/main_test.rego` に、こう書いてある。

```rego
test_red_denied if {
	count(deny) == 1 with input as {"color": "red"}
}
```

これを一緒に読み込むと、どの壊し方でも赤くなる。

```bash
conftest verify -p experiments/01_field_typo -p experiments/detector
conftest verify -p experiments/02_rule_name_typo -p experiments/detector
```

```text
FAIL - detector/main_test.rego -  - data.main.test_red_denied

Error: ... rego_unsafe_var_error: var deny is unsafe
```

実験 1 はテストの失敗、実験 2 と 3 は「`deny` が存在しない」というコンパイルエラーになる。
どちらにせよ CI は止まる。

> Rego で「ポリシーが生きている」ことを保証する手段は、deny が発火するテストしかない。
> テストが 1 つも無い Rego は、壊れても緑に見える状態で運用されることになる。

## テストが採点者 (スライドと同じ例)

`policy/` に 04 章の `cidr.rego` と、スライド「テストが採点者」の `cidr_test.rego` を置いてある。
テストは 3 本。準拠入力が pass、違反入力が deny、欠落入力が deny。

```rego
test_allowed_passes if {
	count(deny) == 0 with input as ok   # input=ok で deny 0 件
}
```

- `with input as ok` = この式の間だけ input を `ok` に差し替える。ファイル無しで入力を作れる
- `test_` で始まるルールがテスト。verify が 1 本ずつ評価し、真なら pass、undefined なら FAIL

```bash
conftest verify -p policy/
```

```text
3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

### ポリシーをわざと壊す

`policy/cidr.rego` の `["cidr"]` を `["cidrs"]` にタイポして、もう一度:

```bash
conftest verify -p policy/
```

```text
FAIL - policy/cidr_test.rego -  - data.main.test_allowed_passes

3 tests, 2 passed, 0 warnings, 1 failure, 0 exceptions, 0 skipped
```

`cidrs` は無いので毎回 null になり、正しい CIDR まで deny される。
テストが無ければ、この壊れ方は「全部 FAIL する CI」として本番で気付くことになる。確認したら戻しておく。
