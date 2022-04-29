# F#でプレゼン
bleis-tift

---

## 自己紹介
![bleis-tift](https://raw.githubusercontent.com/bleis-tift/bleis-tift/main/bleis-tift.svg)

* [id:bleis-tift](https://bleis-tift.hatenablog.com) / [@bleis](https://twitter.com/bleis)
* 2009年ごろからF#やってる
   * F#おじさん

---

## プレゼンツール遍歴
* PowerPoint
* HTML(高橋メソッド)
* LaTeX(Beamer)
* Excel方眼紙生成
* 自作ツール ← イマココ

---

## PowerPoint
* メリット
   * 専用ツール
   * なんだかんだ便利
* デメリット
   * バイナリ(pptxは中身XMLではある)

---

## HTML(高橋メソッド)
* メリット
   * プレーンテキスト
   * お手軽
* デメリット
   * 長いプレゼンにはつらい
   * プレゼン資料っぽい資料(?)にはならない

---

## LaTeX(Beamer)
* メリット
   * プレーンテキスト
   * 柔軟性の塊
* デメリット
   * 書くのがつらい

--

## つらみ
```latex without-running
\documentclass[14pt,dvipdfmx]{beamer}
\setbeamertemplate{navigation symbols}{}
\usepackage{graphicx}
\renewcommand{\familydefault}{\sfdefault}
\renewcommand{\kanjifamilydefault}{\gtdefault}
\setbeamerfont{title}{size=\large,series=\bfseries}
\setbeamerfont{frametitle}{size=\large,series=\bfseries}
\setbeamertemplate{frametitle}[default][center]
\usecolortheme{orchid}
\usefonttheme{professionalfonts} 
\useinnertheme{rounded}
\begin{document}
\frame {\frametitle{header}
  \begin{itemize}
  \item aaa
  \item<2-> bbb
  \item<3-> ccc
  \end{itemize}
}
\end{document}
```

---

## Excel方眼紙生成
* メリット
   * インパクトが強い
   * F#でプレゼン生成
   * コードが色につく(ように実装した)
      * F#はもちろん、C#やTypeScriptにも対応
* デメリット
   * 発表しにくい

---

## 理想のプレゼンツールを考えてみた
* プレーンテキストは必須
* コードに色がついてほしい
* 何ならその場で実行したい
* 資料配布もできるとうれしい
* macでも動かしたい

---

## reveal.js
* markdownで書ける
* コードに色が付く
* 配布も容易
* macで動く
* その場で実行だけできない

おしい・・・

---

## FsReveal
* fsxで書く
   * tooltipが出る
* markdown部分がコメント
   * fsxとして動かせる
   * 実行結果を埋め込める
* コレジャナイ

--

## コレジャナイんです
```fsharp without-running
(**
- title : sample

***

### header
*)
let a = "hello"
(*** include-value: a ***)
```

---

# そこで自作ツール

---

## 方向性
* 入力はmarkdown
* コードの色付けは最小限
* コードの実行はとりあえずF#のみ
* 配布用資料生成はサボりたい
* クロスプラットフォーム

---

## 入力はmarkdown
* 表現力はLaTeXほど要らない
* 書きやすいし読みやすい
* FSharp.Formattingにパーサーがある

---

## コードの色付けは最小限
* F#はFCSでどうとでもなる
* C#もRoslynでいけるけど後回し
* LaTeXは超適当なパーサー書いた
* 別の機会にXML使ったので対応

---

## コードの実行はとりあえずF#のみ
* FCSでどうとでもなる
* F#以外には外部コマンド実行でいいけど後回し
* 最終的には外部コマンド統一がいいかも

---

## 配布用資料生成はサボりたい
* Excel方眼紙とかpptxとかPDF出力はだるい
* reveal.js互換のmarkdownを入力にする
   * 配布はreveal.jsでやればいい

---

## クロスプラットフォーム
* macでも動かしたい
* Avalonia.FuncUIが使ってみたかった
   * XAMLではなくF#でViewが書ける
   * ElmっぽいMVU

---

# 出来上がったのがこれです

--

## Conceal
* Reveal: 見せる、公開する
* Conceal: 隠す、隠ぺいする

---

## コードハイライトと実行
```fsharp
let rec fact n =
  match n with
  | 0 -> 1
  | n -> n * fact (n - 1)

printfn "%d" (5 |> fact)
```

---

## コンパイルエラー
```fsharp
printfn "%A" ("hoge" + 42)
```

---

## スライド配布
* プレゼンツール内でリンクが使える
* [配布資料](https://github.com/bleis-tift/presentation/gh-pages/2022/04-30-fffsharp5)
   * プレゼン中はこのリンクを踏むとツール内で開く

---

## ちなみに
* `WebView` というコンポーネントを使っている
* OutSystems社製
   * ローコードツール作ってる会社
   * ちょっと知ってる

---

## 今後
* 一応、最低限はできたがまだ足りない
* サイズ調整とか
* 自動改行的な機能とか
* もうちょっと非同期でどうこうするとか

---

## 参考にした情報
* [Elmガイド](https://guide.elm-lang.jp/)
* [Avalonia.FuncUI Guides](https://avaloniacommunity.github.io/Avalonia.FuncUI.Docs/guides.html)
* [Avalonia UI Documentation](https://docs.avaloniaui.net/)
* [The Elmish Book](https://zaid-ajaj.github.io/the-elmish-book/)
