# Merry Christmas !

これは[Google Santa Tracker](https://github.com/google/santa-tracker-web)を[AWS S3 WebHosting](https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/dev/WebsiteHosting.html)で動かすためのものです。

## 前提

以下のものが必要です。

* Docker
* node.js v4以上

## まずは自分の手元で確かめる

```
$ docker-compose up
:
:
Attaching to xmas_santa_1, xmas_viewer_1
xmas_santa_1 exited with code 0
```

これによって行われることは、

1. santatrackerのソースのビルド  
  10分くらいかかるので気長に待ちましょう
2. ビルドされたものをnginxでホスティング

です。

`Attaching to ...`が出たら完了で、 http://localhost:3000 にアクセスしましょう。

## サンタさんを公開する

### S3バケットを作る

#### 自分のドメイン名を設定する

[infra/template/index.js]の下記の部分を自分の所有するドメインに変更してください。

```javascript:index.js
const DomainName = "xmas.kinoboku.net";
```

※事前にRoute53にHostedZoneを作ってNSレコード、SOAレコードを登録しておいてください。

参考： http://qiita.com/sadayuki-matsuno/items/4c371ba984d9b22b3737#2%E3%81%8A%E5%90%8D%E5%89%8Dcom%E3%81%ABroute53%E3%81%AEdns%E3%82%92%E7%99%BB%E9%8C%B2%E3%81%97%E3%81%A6%E3%82%B5%E3%83%96%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E3%82%92%E5%A7%94%E4%BB%BB%E3%81%99%E3%82%8B


#### CloudFormationの実行

S3バケットとRoute53のDNSレコードを作ります。

```shell-session
$ cd ./infra
$ npm install
$ AWS_PROFILE=newgyu npm start deploy
```

※ AWS_PROFILEに設定する値は自分の`~/.aws/credentials`の定義に合わせてください

これでS3バケットが作成され、PublicなWebHostingが可能な状態となります。

### S3にsanta-trackerの成果物を配置する

```
$ AWS_PROFILE=newgyu docker-compose -f publish.yaml up
```

これによって行われることは、

1. santatrackerのソースのビルド  
  10分くらいかかるので気長に待ちましょう
2. ビルドされたものを`s3 sync`でS3バケットに配置

です。

http://xmas.kinoboku.net/ にアクセスするとSanta Tracker が動作します。

## だがしかし！

悔しながら青い画面が出たきりでサンタさんの村は出てきません。。

ChromeのDeveloper Consoleを見ると

```
elements_en.js:16280
Uncaught TypeError: (intermediate value)(intermediate value)(intermediate value)(intermediate value)(...) is not a function(…)(anonymous function) @ elements_en.js:16280
```

というメッセージが出ておりビルドしたSanta Trackerのソースにエラーがあるようです。
Santa Trackerのビルドは[gulpfile.js](https://github.com/google/santa-tracker-web/blob/master/gulpfile.js#L386-L408)を見ていただくとわかるようにClosure Compilerで連結＋minifyをしています。
ここの処理で作られる`elements_en.js`に何か問題があるようです。力尽きてしまったのでどなたか教えていただけると幸いです。

2015年版のSanta Trackerのソースには[公式README](https://github.com/google/santa-tracker-web/blob/master/README.md)どおりに素直にビルドできないいくつかの問題がありました。
[Dockerfile](Dockerfile)の中でパッチを当てて吸収したつもりなのですが、対処方法に間違っているところがあるのかもしれません。

Dockerfileでやっているパッチ内容を簡単に解説します。

### 1. 実はgulp-cliが必要

公式説明では`npm install`だけでいいぜ、となっているのですが、[package.jsonのpost install](https://github.com/google/santa-tracker-web/blob/master/package.json#L6)でgulp-cliを必要としています。

### 2. Dockerコンテナ内でrootユーザーで動かすにはbowerにオプション指定が必要

`bower install`は非rootユーザー前提にしているらしく、rootユーザーで実行するには`--allow-root`オプションが必要でした。  
（これは私がDockerですべてを片付けようとして、めんどくさいからrootユーザーを使ったが故の問題です）

### 3. closure-compilerのjarにバージョン番号が付いている

`gulp-closure-compiler`は`./components/closure-compiler/compiler.jar` というファイルを期待しているのですが、bowerでインストールした場合にファイル名が異なるようでシンボリックリンクを作りました。

### 4. そもそもコンパイルでコケる

* https://github.com/google/santa-tracker-web/issues/2
* https://github.com/google/santa-tracker-web/pull/3

Googleの担当によると「2016年版で直しとくよ！」ということらしい。


