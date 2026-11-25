# まいにちクイズ

小学1年生向けの、国語・算数の家庭学習クイズ。

- 国語: 「おはなしのページ(絵本)」→ 4問のクイズ
- 算数: 「かんがえかたのページ」→ 4問のクイズ(おはじき・10のわくの図つき)
- 名前ごとの記録(1回で正解した問題、まちがえた問題)と、まちがえた問題だけのやりなおし
- 記録はブラウザの `localStorage` のみ。サーバーには何も送らない
- 記録のファイル保存(JSON / CSV)と、コピーした文字・ファイルからの読み込み
- 問題・あらすじの読み上げ(Web Speech API。端末の日本語音声を使う)
- ライト/ダーク両対応、スマホ幅優先。ビルド不要、外部ライブラリなし

## しくみ

```
index.html            画面と動作(クイズの中身は入っていない)
quizzes/
  index.json          読み込むクイズのファイル名の一覧
  <id>.json           クイズ1件(お話・問題・図の指定)
tools/build-index.sh  quizzes/index.json を作り直す
```

`index.html` は起動時に `quizzes/index.json` を読み、そこに書かれた各 JSON を読み込む。クイズを足すときは `index.html` を変えない。

## 動かす

`fetch` で JSON を読むので、`file://` で直接開くと動かない。サーバー経由で開く。

```sh
python3 -m http.server 8000   # http://localhost:8000
```

Google Fonts(Zen Maru Gothic)だけ外部から読み込む。読めない場合はシステムのゴシック体になる。

## 公開(GitHub Pages)

リポジトリの Settings → Pages で、ブランチのルートを公開する。`index.html` と `quizzes/` がそのまま配信される。

## クイズを足す

1. `quizzes/<id>.json` を作る(下の形)。ファイル名は `<id>.json` にする。
2. `sh tools/build-index.sh` で `quizzes/index.json` を作り直す。
3. commit して push する。

`id` は先頭に日付を入れる(`2026-10-23-kokugo` など)。一覧は `id` の順に並び、新しいものが上に出る。**`id` は記録のキーなので、あとから変えない。**

```json
{
  "id": "2026-10-23-kokugo",
  "date": "10がつ23にち(きん)",
  "subject": "こくご",
  "title": "タイトル",
  "bookLabel": "おはなし",
  "note": "一覧に出る一行説明",
  "story": ["1ページめ", "2ページめ"],
  "prompts": ["おうちの方への声かけ", "…"],
  "pageArts": [{ "type": "scene", "kind": "kids" }, { "type": "scene", "kind": "away" }],
  "qs": [
    {
      "tag": "だれが？",
      "text": "問題文",
      "say": "読み上げ用(省略可)",
      "choices": ["A", "B", "C"],
      "answer": [0],
      "multi": false,
      "scene": "kids",
      "hint": "正解後と、まちがい後に出る一言"
    }
  ]
}
```

- `story` はページ(1ページ1要素)。`prompts` は同じ数だけ、おうちの方への声かけ。
- `answer` は正解の選択肢の番号(0始まり)。`multi: true` のときは2つ選ぶ(`answer` も2つ)。
- `bookLabel` は省略可(既定は「おはなし」。算数は「かんがえかた」)。
- `pageArts` は省略可。`story` と同じ数のときだけ使う。省略すると既定のさし絵。
- 問題のさし絵は `art` に図の指定を書く(下)。国語で既定の絵なら `scene` でもよい。

### 図の指定(`pageArts` の要素、問題の `art`)

| type | 項目 | 内容 |
|---|---|---|
| `dots` | `a`, `b`, `c` | おはじきを a+b こ並べて、最後の c こを取る図。a+b は10以下 |
| `tenFrame` | `a`, `b`, `mode` | 10のわく。`mode` は `setup`(a こ入れた状態)か `solved`(10をつくった状態。a+b が10以上のとき) |
| `plusMinus` | なし | 「ふえる＝たしざん、へる＝ひきざん」の見分けかた |
| `scene` | `kind` | かたつむりと あおむしの図。`title` `kids` `away` `happy` `cloud` |

図の指定は、決まった形だけを受け付ける(SVG の文字列は受け付けない)。新しい種類の図が必要なときは、`index.html` の `resolveArt` と図の関数を足す。

## 読み込み時の安全対策

クイズの JSON は、読み込み時に検証して整える。

- 文字数、問題数、選択肢の数、`answer` の範囲を確認し、合わないクイズは一覧に出さない。
- 画面に出す文字は HTML としてエスケープする。
- `index.json` に書けるファイル名は `[A-Za-z0-9_.-]+.json` だけ(`../` などは読まない)。

## 記録のしくみ

- `mq-profiles-v1`: 名前の一覧と、いま選んでいる名前
- `mq-runs-<profileId>`: その人の記録(1回あそぶごとに1件の run)
- run: `{ id, quizId, quizTitle, subject, retry, startedAt, updatedAt, total, items }`
- `items`: `{ <問題の番号>: { first: 1回で正解したか, tries: かいすう, done: 正解したか } }`
- 「まちがえた問題」は、その問題の**いちばん新しい記録**が `first: false` のもの。やりなおしで1回で正解すると○に戻る。
- 読み込み(`importText`)は、`quizId` が一覧にあるもの以外を捨て、数値と真偽値を整えてから取り込む。

## 内容の方針

- お話・問題・さし絵は、すべてオリジナル。教科書や宿題プリントの本文・問題文・さし絵は入れない。
- 子どもの名前や学校名は、データにもコードにも入れない(名前は端末内の `localStorage` だけ)。

## 未確認のこと

- 実機(スマホ・タブレット)での見た目と、読み上げの声
- ファイル保存の挙動(claude.ai の中では `downloads` 機能、単体では `<a download>`)
- ブラウザを使わない簡易テストで、画面の流れ(読み込み → 一覧 → 絵本 → クイズ → 記録 → やりなおし → 保存/読み込み)と、不正な JSON の無視だけ確認済み
