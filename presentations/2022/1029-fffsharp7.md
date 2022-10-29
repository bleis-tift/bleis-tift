# コンピュテーション式一巡り
bleis-tift

---

## 自己紹介
![bleis-tift](https://raw.githubusercontent.com/bleis-tift/bleis-tift/main/bleis-tift.svg)

* [id:bleis-tift](https://bleis-tift.hatenablog.com) / [@bleis](https://twitter.com/bleis)
* 2009年ごろからF#やってる
   * F#おじさん

---

## コンピュテーション式とは
> コンピュテーション式は、その種類に応じて、
> モナド、モノイド、モナド変換子、および
> アプリカティブファンクターを表現する方法と
> 考えることができます。

---

# 日本語でおｋ

---

## `let` 式を考えてみましょう
```fsharp without-running
let x = 10
x * 2
```

これを、`let` 構文を使わずに実現しようとすると？

---

## ラムダ式による変数導入
`let` は変数の導入なので、ラムダ式で代替可能

```fsharp without-running
// 元のコード
// let x = 10
// x * 2
10
|> fun x -> x * 2
```

---

## カスタマイズ
```fsharp without-running
// 元のコード
// let x = 10
// x * 2
X.LetBinding(10, fun x -> x * 2)
```

このようにできれば、
元のコードの意味をカスタマイズできる
→基本的なコンピュテーション式の考え方

---

## コンピュテーション式
* F#の構文をメソッド呼び出しの形に変形
* メソッドの処理で動作をカスタマイズ

つまり、F#の構文の意味がカスタマイズできる！

--

## 余談: 他の言語では？
* Haskellの `do`
* Scalaの `for-yield`
* (C#のクエリ式)

---

## コンピュテーション式の例
```fsharp without-running
// コンピュテーション式
x {
  let! a = f ()
  let! b = g ()
  return a * b
}
// 展開結果(例)
x.Bind(f (), fun a ->
x.Bind(g (), fun b ->
  b.Return(a * b)))
```

---

## 何もしないコンピュテーション式
```fsharp without-running
type X () =
  member _.Bind(x, f) = f x
  member _.Return(x) = x

let x = X ()
```

---

## 何に使えるか
* ある種の定型処理を、手続き的に書けるよう
   にする
   * 非決定計算
   * 非同期計算
   * `option` の値を取り出しての計算

---

## 例: `option` の値を取り出しての計算
```fsharp without-running
match o1 with
| Some a ->
    match o2 with
    | Some b ->
        Some (a + b)
    | None -> None
| None -> None
```

`match` のネストが面倒！

---

## 書き換えてみる
```fsharp without-running
type B () =
  member _.Bind(x, f) =
    // Option.bind f x でも可
    match x with
    | Some a -> f a
    | None -> None
  member _.Return(x) = Some x
let x = B ()
x {
  let! a = o1
  let! b = o2
  return a + b
}
```

---

## 比較
```fsharp without-running
// オリジナル
match o1 with
| Some a ->
    match o2 with
    | Some b ->
        Some (a + b)
    | None -> None
| None -> None
// コンピュテーション式
b {
  let! a = o1
  let! b = o2
  return a + b
}
// de-sugar
b.Bind(o1, fun a ->
b.Bind(o2, fun b ->
  b.Return(a + b)))
```

--

## 余談: 他の言語との違い
* コンピュテーション式
   * 「文脈に無関係なオブジェクト」に定義
   * 何を使うのかは、使用者が明示的に指定
* そのほかの言語
   * 定義方法は色々
   * 何を使うのかは、コンパイラが探す

---

## `Delay` 変換
* ビルダーが `Delay` メソッドを持っている場合、  
   `Delay` 変換が行われる。
* コンピュテーション式全体を  
   `b.Delay(fun () -> ...)` で囲む
* `Delay` に渡された関数の起動を選択できる
* `Delay` は他の変換で使われることも
   * こっちが本命

--

## `Delay` 変換


```fsharp without-running
type B () =
  member _.Delay(f) = f // 関数を実行しない
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
let x = B ()
x {
  let! a = o1
  let! b = o2
  return a + b
}
// こうなる(全体の型は、unitを受け取る関数)
x.Delay(fun () ->
  x.Bind(o1, fun a ->
  x.Bind(o2, fun b ->
    x.Return(a + b))))
```

---

## `Run` 変換
* ビルダーが `Run` メソッドを持っている場合、  
   `Run` 変換が行われる。
* コンピュテーション式全体を  
   `b.Run(...)` で囲む
* `Delay` よりも外側になるため、`Delay` 変換で  
   関数を起動しなかった場合、それを起動できる

--

## `Run` 変換

```fsharp without-running
type B () =
  member _.Run(f) = f () // Delayした関数をここで実行
  member _.Delay(f) = f
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
let x = B ()
x {
  let! a = o1
  let! b = o2
  return a + b
}
// こうなる
x.Run(
  x.Delay(fun () ->
    x.Bind(o1, fun a ->
    x.Bind(o2, fun b ->
      x.Return(a + b)))))
```

--

## `Run` の応用
```fsharp without-running
type B (v: 'a) =
  member _.Run(f) = f () |> Option.defaultValue v
  member _.Delay(f) = f
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
let x v = B ()
// o1かo2がNoneの場合、-1
x -1 {
  let! a = o1
  let! b = o2
  return a + b
}
```

---

## `Zero` 変換
* 複数個所で出てくる
   * `else` のない `if` の `else` 側
   * コンピュテーション式ではない式の変換
   * `DefaultValue` の付いたビルダーでの `do!`
* `b { () }` で出てくる
   * `b.Run(b.Delay(fun () -> b.Zero()  
      ))`

---

## `While` 変換
* `while e do ce` に対する変換
   * 要は、`while` 式に対する変換
* `b.While((fun () -> e),  
   b.Delay(fun () -> ceの変換結果))`
* `Delay` が出てくる

--

## `While` 変換
```fsharp
type B () =
  member _.Run(f) = f ()
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then None
    else
      match body () with
      | Some _ -> this.While(cond, body)
      | None -> None
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
  member _.Zero() = None
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    return 10
} |> printfn "%A"
```

--

## `While` 変換
* 結果に「あれ？」って思った？
* 変換結果を読み解いてみよう

--

## `While` 変換
```fsharp without-running
type B () =
  member _.Run(f) = f ()
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then None // 最終的には、ここに来て全体としてNoneが返る
    else
      match body () with
      | Some _ -> this.While(cond, body) // body ()の結果は捨てる
      | None -> None
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
  member _.Zero() = None
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    return 10
}
// ざっくりこうなる
x.Run(x.Delay(fun () ->
  let mutable i = 0
  b.While((fun () -> i < 5), b.Delay(fun () ->
    printfn "loop"
    i <- i + 1
    b.Return(10)))))
```

--

## `return` で `return` するには・・・
* 一応できます
   * 状態を引き回す
   * 継続を使う
* 詳しくは後述

---

## `Combine` 変換
* `ce1; ce2` に対する変換
   * 要は、二つの式の連続に対する変換
* `b.Combine(ce1の変換結果,  
   b.Delay(fun () -> ce2の変換結果))`
* `Delay` が出てくる
* `While` にはほぼ必須

--

## `While` にはほぼ必須？
```fsharp without-running
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    // 気持ち悪いけどいったん目をつぶってください！
    return -1
  // Combineがないと、whileの後にコードが書けない
  return 10
}
```

--

## `Combine` 変換
```fsharp
type B () =
  member _.Run(f) = f ()
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then Some (Unchecked.defaultof<_>)
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.Combine(x, f) =
    match x with
    | Some _ -> f ()
    | None -> None
  member _.Bind(x, f) = Option.bind f x
  member _.Return(x) = Some x
  member _.Zero() = None
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    return -1
  return 10
} |> printfn "%A"
```

---

## `return` で `return` する
```fsharp without-running
type FlowControl = Break | Continue // 実行を止めるか、続けるか
type B () =
  member _.Run(f) = f () |> fst
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then this.Zero()
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.OldCombine(x, f) =
    match x with
    | Some _ -> f ()
    | None -> None
  member _.Combine(first, rest) =
    // xだけではなく、FlowControlも見る
    // Breakだったら、xがNoneだったとしても続けない
    // -> returnでreturnできるようになる
    match first with
    | x, Break
    | (Some _ as x), Continue -> (x, Break)
    | None, Continue -> rest ()
  member _.Bind(x, f) = (Option.bind (f >> fst) x, Continue)
  member _.Return(x) = (Some x, Break)
  member _.Zero() = (None, Continue)
```

--

## 試してみる
```fsharp
type FlowControl = Break | Continue
type B () =
  member _.Run(f) = f () |> fst
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then this.Zero()
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.Combine(first, rest) =
    match first with
    | x, Break
    | (Some _ as x), Continue -> (x, Break)
    | None, Continue -> rest ()
  member _.Bind(x, f) = (Option.bind (f >> fst) x, Continue)
  member _.Return(x) = (Some x, Break)
  member _.Zero() = (None, Continue)
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    return -1
  return 10
} |> printfn "%A"
```

--

# `return` で `return` できた！

---

## 別の問題
```fsharp
type FlowControl = Break | Continue
type B () =
  member _.Run(f) = f () |> fst
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then this.Zero()
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.Combine(first, rest) =
    match first with
    | x, Break
    | (Some _ as x), Continue -> (x, Break)
    | None, Continue -> rest ()
  member _.Bind(x, f) = (Option.bind (f >> fst) x, Continue)
  member _.Return(x) = (Some x, Break)
  member _.Zero() = (None, Continue)
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    do! None // return -1をdo!にした
             // 実際には、unit optionを返す関数が書いてあると思ってください
  return 10
} |> printfn "%A"
```

---

## `do!` の問題
* `do! e` は `let! () = e in b.Return()`  
   に変換される
* 勝手に `unit option` が出てくる
* 困った・・・

--

## `DefaultValue` 属性
* `Zero` に `DefaultValue` 属性を追加すると  
   b.Return()の代わりにb.Zero()を使ってくれる  
   ようになった
* `b.Zero()` の型は `'a option`
* 勝てる・・・！

--

## やってみた

```fsharp
type FlowControl = Break | Continue
type B () =
  member _.Run(f) = f () |> fst
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then this.Zero()
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.Combine(first, rest) =
    match first with
    | x, Break
    | (Some _ as x), Continue -> (x, Break)
    | None, Continue -> rest ()
  member _.Bind(x, f) = (Option.bind (f >> fst) x, Continue)
  member _.Return(x) = (Some x, Break)
  [<DefaultValue>]
  member _.Zero() = (None, Continue)
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    do! None
  return 10
} |> printfn "%A"
```

--

# やったー！

---

## `return` で `return` する(別解)
```fsharp
type B () =
  // 初期継続を渡して結果を取り出す
  member _.Run(f) = f () id
  member _.Delay(f) = f
  member this.While(cond, body) =
    if not (cond ()) then this.Zero()
    else this.Combine(body (), fun () -> this.While(cond, body))
  member _.Combine(first, rest) =
    // firstの処理を捨てて、後続処理を起動
    fun k -> first (fun _ -> rest () k)
  member this.Bind(x, f) =
    match x with Some x -> f x | None -> this.Zero
  // returnでは、継続を捨てて、xを返す(後続の処理を実行しない)
  member _.Return(x) = fun _ -> x
  // zeroでは、継続を起動する(後続の処理を実行する)
  [<DefaultValue>]
  member _.Zero() = fun k -> k Unchecked.defaultof<_>
let x = B ()
x {
  let mutable i = 0
  while i < 5 do
    printfn "loop"
    i <- i + 1
    return -1
  return 10
} |> printfn "%A"
```

---

## 入りきらなかった話題
* `if` とか `use!` とかその他諸々
* カスタムオペレーション
* アプリカティブ
   * [zeclさんの記事](https://zenn.dev/zecl/articles/a330820e9277cf)を読めば完璧ですし・・・
* StateMachineによる実装
   * まだ完全には理解できてない

---

## まとめ
* コンピュテーション式は・・・
   * 構文の意味をカスタマイズできる
   * 面倒な処理を「裏側」に隠せる
* `return` で `return` する
   * 状態を引き回す
   * `Zero` には `DefaultValue` を！
* 全然一巡りできなかったよ・・・
