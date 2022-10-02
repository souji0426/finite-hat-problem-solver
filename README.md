# finite-hat-problem-solver
有限な帽子パズルを解くプログラム。
※3人3色でも危険！！！！

# 開発環境
Perlを使用。バージョンはv5.24.3。

#使い方
##ゲームルール設定
start.plを実行する。
コマンドは「perl -w start.pl [囚人数] [色数] [発言パスの有無] [発言同時モード]」
囚人数・色数は2以上の数にすること。
そもそも囚人が1人のゲームは運任せにしかなりえないから数学の対象外で、
色の数は1つなら囚人が常に勝つという面白くない結果しか生まれない。

発言パスの有無はまだ実装中なのでとりあえず「off」で。

発言同時モードはデフォルトで「on」で、「off」の挙動も実装中。

なので今現在は「perl -w start.pl [囚人数] [色数] off on」と実行すること。
※3人3色でも危険！！！！

##帽子の見え方を決める
上記プログラム実行後、「setting」というフォルダができる。
これはパズルに関する様々な設定を格納するフォルダ。
その中に「visibility_gragh.txt」というファイルができる。
例えば2人2色で上記プログラムを実行すれば以下のような内容になる。
```
[a_0]
a_1

[a_1]
a_0

```
各a_0とa_1は、プログラムが勝手に付けた2人の囚人の名前です。
そして[a_0]から[a_1]までの間にはa_0が見える囚人の名前、つまりa_1が書いてあります。
なのでこのa_1を削除して保存すれば、このゲームにおいて囚人a_0はa_1の帽子が見えない、
つまり何も見えない状態でゲームに参加しなくてはいけないという設定をしたことになります。

上記プログラム実行後のこのファイルは、どんな人数でも「どの囚人も自分以外の全ての帽子が見える」状態になっているので、
誰か見えない帽子が見えない囚人を設定したいときは、このファイルを編集して保存してください。

##計算プログラム実行
続いて「perl -w calc.pl」を実行してください。
これによって設定に従ってパズルの開放の解析を始めます。
解析の途中経過についてはコンソール画面に出力されます。
※3人3色でも危険！！！！

##レポートプログラム実行
上記プログラムが正常終了すれば「perl -w report.pl」を実行してください。
上記プログラムによって計算された種々のデータはresult_dataというフォルダに格納されており、
そのフォルダと設定内容から、設定したパズルにどのような戦略が存在したのかをレポートします。
このレポートはcalc_dataフォルダのrepott.txtを見てください。
