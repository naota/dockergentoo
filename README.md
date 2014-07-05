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
自分の情報を設定する。この設定がコンテナのメンテナとして使われる。
./bin/update.sh が2つのコンテナを構築する。

```
$ export MAINTAINER="Naohiro Aota <naota@gentoo.org>"
$ ./bin/update.sh
```

次にdistfiles(ソースコード保管ディレクトリ)とpackages(バイナリパッケー
ジ保管ディレクトリ)として機能する"distfiles"というコンテナを構築し、実
行する。

```
$ ./bin/build.sh distfiles
$ docker run -v /usr/portage/distfiles -v /usr/portage/packages --name distfiles ${NAMESPACE}/distfiles true
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
