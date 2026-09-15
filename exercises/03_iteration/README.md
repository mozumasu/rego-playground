# 03. 繰り返し — some と every

スライド「some で列挙、every で全件」のコードと input をそのまま置いてある。
`in` は `services` の 3 件を 1 つずつ変数に入れて条件を試す。変数が 1 つなら値、2 つならキーと値。

## まず走らせる

```bash
conftest test -p policy/ input.json
opa eval -d policy/ -i input.json 'data.main.all_owned' -f pretty
```

```text
FAIL - input.json - main - api: replicas は 2 以上
FAIL - input.json - main - batch: replicas は 2 以上

2 tests, 0 passed, 0 warnings, 2 failures, 0 exceptions
```

```text
undefined
```

| name | `svc.replicas < 2` | | `svc.owner != ""` | |
| --- | --- | --- | --- | --- |
| api | 1 < 2 | msg を出す | "sre" | ✅ |
| web | 3 < 2 | この件は消える | "" | ❌ |
| batch | 1 < 2 | msg を出す | "data" | ✅ |

some は満たした件ごとに msg が 1 つ。every は 1 件外れた時点で `all_owned` が undefined になる (出力に現れない)。

## Q1. conftest test が通るようにしよう

`input.json` だけを書き換えて、`conftest test` を `1 test, 1 passed` にする (deny が空だとファイル単位で 1 件と数える)。

<details><summary>答え</summary>

api と batch の `replicas` を 2 以上にする。deny は「満たした件」だけ残るので、該当が 0 件なら空になる。
ポリシー側を直す必要はない。

</details>

## Q2. all_owned が true になるようにしよう

`input.json` だけを書き換えて、`opa eval ... 'data.main.all_owned'` を `true` にする。

<details><summary>答え</summary>

web の `owner` に何か入れる (`"web-team"` など)。every は全件が条件を満たしたときだけ真になる。
逆に、api の owner も空にしても結果は undefined のまま。「何件外れたか」は見ていない。

</details>

## おまけ: 変数の数で取れるものが変わる

```bash
opa eval -i input.json '[x | some x in input.services]' -f pretty      # 値だけ
opa eval -i input.json '[k | some k, _ in input.services]' -f pretty   # キーだけ
```

`some name, svc in ...` はこの 2 つを同時に取っている。
