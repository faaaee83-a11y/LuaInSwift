# Psych Lua 互換テスト（Swift Playgrounds 版）

Lua 5.1.5 の C ソースを組み込んだ Swift Playgrounds 用の App プロジェクトです。

## 手順
1. Codespaces か Mac で、このフォルダの中で `./setup.sh` を実行（Lua 5.1.5 が `CLua/` に入ります）
2. フォルダごと iPad に持ってくる（Codespaces ならフォルダを右クリックしてダウンロード）
3. iPad の「ファイル」で `PsychLuaPlayground.swiftpm` を開くと Swift Playgrounds が起動
4. 「テストを実行」を押す。「Lua を追加」で自分の MOD の .lua も試せます

## 注意
- Swift Playgrounds が C ターゲットを受け付けない場合は、ビルド時に C ターゲット非対応のエラーが出ます。
- 使う Lua は素の 5.1.5 です（LuaJIT ではありません）。
