# 03. 繰り返し — some と every

スライド「some で列挙、every で全件」のコードと input をそのまま置いてある。
`in` は `services` の 3 件を 1 つずつ変数に入れて条件を試す。変数が 1 つなら値、2 つならキーと値。

## 1. some は条件を満たした件だけ残す

```bash
conftest test -p policy/ input.json
```

```text
FAIL - input.json - main - api: replicas は 2 以上
FAIL - input.json - main - batch: replicas は 2 以上

2 tests, 0 passed, 0 warnings, 2 failures, 0 exceptions
```

| name | `svc.replicas < 2` | |
| --- | --- | --- |
| api | 1 < 2 | msg を出す |
| web | 3 < 2 | この件は消える |
| batch | 1 < 2 | msg を出す |

満たした件ごとに msg が 1 つ。for + if + append を 1 行で書いている。

## 2. every は全件満たすときだけ真

```bash
opa eval -d policy/ -i input.json 'data.main.all_owned' -f pretty
```

```text
undefined
```

web の owner が空なので、1 件外れた時点で `all_owned` は undefined になる (出力に現れない)。
`input.json` の web の owner を `"web-team"` にして再実行すると `true` になる。

## 3. 変数の数で取れるものが変わる

```bash
opa eval -i input.json '[x | some x in input.services]' -f pretty      # 値だけ
opa eval -i input.json '[k | some k, _ in input.services]' -f pretty   # キーだけ
```

前者は `{ "replicas": 1, "owner": "sre" }` のような値の配列、後者は `["api", "batch", "web"]`。
`some name, svc in ...` はこの 2 つを同時に取っている。
