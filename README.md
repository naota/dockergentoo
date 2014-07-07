# これはなにか
以下のやりたいことを実現する

- GentooのebuildをDocker上でビルドしてテストしたい
- ビルドが成功したらそのバイナリを残したい
- ビルドが失敗したらそのエラーログを取得したい
- 「自分のebuild」をテストしたい

# はじめにやること

まずはstage3だけからなる"gentoo"というコンテナイメージと、Portageツリー
を提供する"portage"というデータコンテナイメージを構築し、"portage"とい
うコンテナを実行する。 Dockerfileを構築するために MAINTAINER環境変数に
自分の情報を設定する。この設定がコンテナのメンテナとして使われる。また、
"distfiles"というソースコードおよびバイナリパッケージを保管するコンテナ
も作って実行しておく。全て、update.shがよしなにやってくれる。

```
$ export MAINTAINER="Naohiro Aota <naota@gentoo.org>"
$ ./bin/update.sh
```

# コンテナの中でのemerge

コンテナの中でemergeを行なうにはbuild-package.shを使うと便利。 flagは
"flaggie <flag>"という形でevalされる。USEフラグを設定してemergeしたい時
に使う。

```
$ ./bin/build-package.sh <flag> <package>
e.g.
$ ./bin/build-package.sh 'app-editors/emacs +X' 'app-editors/emacs'
$ ./bin/build-package.sh '' 'pficommon'
```

こうするとemergeが実行されて、バイナリパッケージが生成される。emergeが
失敗した場合、 "results/"以下に/var/tmp/portage以下をtar.xz形式で固めた
ものが出力される。失敗した場合はこれを見てデバッグができるというわけ。

# 自分のebuildをテストしたい

build-package.sh はPortageツリーに入っているものだけをテスト可能で、自
分のebuildのテストには使えない。そういう時は test-ebuild.sh を使う。

```
$ ./bin/test-ebuild.sh <flag> <ebuild file>
e.g.
$ ./bin/test-ebuild.sh '' 'foo-2.3.0.ebuild'
```

こうすると自分の書いたfoo-2.3.0.ebuildをふくむようなoverlayが構築されて、
コンテナの中で/overlayで見えるようになる。なおかつ、自動的に
PORTDIR_OVERLAYのパスも通り、foo-2.3.0.ebuildに対応するようにemergeを実
行してくれる。

# USEフラグ以外にも設定したい

emergeの前準備はだいたいUSEフラグの設定ぐらいですむのだけれど、時々それ
だけでは足りないこともある。他にもデバッグ用に環境を作りたいこともある。
そんな時のために shell.sh が使えるようになっている。

```
$ ./bin/shell.sh [<ebuild>]
```

これでshell環境に入ることができる。 ebuildを指定した場合には、その
ebuildをふくむoverlaysが/overlayにできている。/build/dockerbuild.sh
<flag> <package> するとバイナリを使ったり作ったりフラグを立てたりといっ
た作業をしてくれる。(ようするにbuild-package.shはコンテナの中でこのスク
リプトを叩いているだけ)

# 時々やること

update.shはその名が語るように、"gentoo"と"portage"のコンテナイメージを
更新する仕事をしてくれる。時々更新してやると、その時の最新のstage3と
portage snapshotを使ったものになる。

```
$ export MAINTAINER="Naohiro Aota <naota@gentoo.org>"
$ ./bin/update.sh
```

# 自分でやること

いまのところ途中でCtrl-Cで止めてしまった時の途中のコンテナと、昔のコン
テナイメージは削除されない。自分で"docker ps -a"や"docker images"を見て
掃除しよう。
