# Go dev boilerplate

VSCode + Docker + Remote Container + Air で構成するシンプルな Go 開発環境の作り方

## 使用方法

1. このリポジトリをクローンする

``` console
git clone https://github.com/fs5013-furi-sutao/go-dev-boilerplate.git
```

2. このローカルリポジトリを VSCode で開く
3. コンテナを作成する

``` console 
docker-compose build
```

4. コンテナを起動する

``` console
docker-compose up -d
```

5. VSCode で開発コンテナに接続する

VSCode の左下にある `><` マークを押す > [reopen in container] を選択

## その他操作

### コンテナのログを表示

``` console
docker-compose logs -f web
```

### 起動コンテナのプロセスを確認

``` console
docker ps
```

### コンテナを停止

``` console
docker-compose stop
```

### 過去に起動コンテナの全プロセスを確認

``` console
docker ps -a
```

### コンテナを削除

``` console
docker-compose 
```

### コンテナの全イメージを表示

``` console 
docker images
```

### コンテナイメージを削除

``` console
docker rmi go-dev-boilerplate_web
```

## Go 開発環境構築方法の説明

Docker, VSCode Remote Container, Air による Go 開発環境構築

### やりたいこと

Docker と VSCode Remote Container による Go の Web サーバ開発環境を構築する

ローカルに Go をインストールすることなく、

- コード補完
- コード変更があるたびに再ビルド（ライブリロード）

の Go 開発環境を構築

### 開発環境の構築

#### ディレクトリ構造

```
.
|
├── .devcontaier/
|      └── devcontainer.json
├── .air.toml
├── docker-compose.yml
└── Dockerfile
```

#### コンテナ設定

ここでは Go 拡張機能で使用する language server に必要な gopls や、
ライブリロードに必要な Air のバイナリインストール＆ビルドを行っている。

`/Dockerfile`
``` Dockerfile
FROM golang:1.16.3-alpine

ENV GO111MODULE on

WORKDIR /go/src/app

RUN apk update \
  && apk add git \
  && go install github.com/cosmtrek/air@latest \
  && go get -u golang.org/x/tools/gopls \
  github.com/ramya-rao-a/go-outline
```

`/docker-compose.yml`
``` yaml
version: "3.8"

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: "air"
    tty: true
    stdin_open: true
    command: "air"
    volumes:
      - ./app:/go/src/app
    ports:
      - 8080:8080
    security_opt:
      - apparmor:unconfined
    cap_add:
      - SYS_PTRACE
```

#### ライブリロード設定

`.air.toml` でライブリロードの設定を行う。
今回は、公式のサンプルコードをそのまま使う。

air/air_example.toml  
https://github.com/cosmtrek/air/blob/master/air_example.toml

#### コンテナ接続設定

VSCode Remote Container 用の設定をする。

extensions の部分で、ワークスペースに任意の VSCode 拡張をインストールすることができる。
今回は、最低限の設定として Go の VSCode 拡張を入れている。



`/.devcontainer/.devcontainer.json`
``` json
{
	"name": "Go-Practice",
	"dockerComposeFile": [
		"../docker-compose.yml",
	],
	"service": "web",
	"workspaceFolder": "/go/src/app",
	"settings": {
		"terminal.integrated.defaultProfile.linux": "ash",
		"terminal.integrated.profiles.linux": {
			"ash": {
				"path": "/bin/ash",
			}
		},
		"go.toolsManagement.checkForUpdates": "off",
		"go.gopath": "/go",
		"go.gocodeAutoBuild": true,
		"go.formatTool": "gofmt",
		"go.useLanguageServer": true,
		"editor.formatOnSave": false,
		"[go]": {
			"editor.formatOnSave": true
		}
	},
	"extensions": [
		"golang.go"
	],
}
```

他にも、今回は軽量なalpineイメージを使用するので、

``` json
		"terminal.integrated.defaultProfile.linux": "ash",
		"terminal.integrated.profiles.linux": {
			"ash": {
				"path": "/bin/ash",
			}
		},
```

の部分でワークスペースで使用するシェルに ash を指定している。

alpine でも bash を使いたい場合は、イメージビルド時に bash を入れたりするなど、適宜カスタマイズする。

### 開発環境の起動

#### Docker イメージのビルド

``` console
docker-compoase build
```

#### コンテナの立ち上げ

``` console
docker-compose up -d
```

コンテナのログを見ると、ライブリロードのairが立ち上がっていることがわかります。

``` console
docker-compose logs -f web
```

`実行結果: `
``` console
web_1  |   __    _   ___
web_1  |  / /\  | | | |_)
web_1  | /_/--\ |_| |_| \_  // live reload for Go apps, with Go
web_1  |
```

#### 開発コンテナ接続

Remote Container でコンテナに接続する方法はいくつかあります。以下のうちどれかを行う。（どれでもいい）

以下、全て VSCode での作業

- [Cmd + Shift + P] > [reopen in container]を選択
- VSCode の左下にある >< を押す > [reopen in container] を選択
- 左側のアイコン(Remote Explerer) > Containers > 該当のコンテナを選択

#### コーディングしてみる

Go コンテナの中に入ることができたので、とりあえず Gin で Web サーバーを立てて動作を確認する。

``` console
go mod init プロジェクト名
```

で go.mod を作成したら、

``` console
go get -u github.com/gin-gonic/gin
```

で gin をインストール。

#### サーバー立ち上げ

``` console
touch ./main.go
```

`/main.go`
``` go
package main

import "github.com/gin-gonic/gin"

func main() {
    r := gin.Default()
    r.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{
            "message": "pong",
        })
    })
    r.Run() 
}
```

#### 動作確認

http://localhost:8080/ping

```
{ "message": "pong" }
```

動いていることを確認できた。

#### ライブリロードの確認

`main.go` の以下のように変えてみる。

``` go
	r.GET("hoge", func(c *gin.Context) { // change: ping -> hoge
		c.JSON(200, gin.H{
			"message": "fuga", // change: pong -> fuga
		})
	})
```

#### 再度動作確認

``` console
web_1  | main.go has changed
web_1  | building...
web_1  | running...
web_1  | [GIN-debug] GET    /ping                     --> main.main.func1 (3 handlers)
web_1  | [GIN-debug] GET    /hoge                     --> main.main.func2 (3 handlers)
```

http://localhost:8080/hoge

```
{ "message": "fuga" }
```

変更が反映されていることがわかる。

## この環境のメリット/デメリット

### メリット

- Docker, VSCode があれば作れる
- ローカルに Go をインストールせずに、コード補完等のサポートが効く
- コードを変更すると、自動でソースコードをリビルドしてくれる
- docker コマンドをいちいち流さなくても良い

### デメリット

- git 管理の構成を考えるのが難しい
- 1 コンテナにつき開ける VSCode のウィンドウが一つ
- 何らかのポートを開けっぱなしにするとき、VSCode のデバッグが使えない

### デバッグと Air が共存できない例

1. 変更があるたびにソースコードがビルドされ、ポート:8080で Gin の Web サーバが立ち上がっている。

2. ここで、VSCode でデバッグを行うと、デバッグのためにソースコードがビルドされる。

3. デバッグでのビルド時、同じくポート:8080で Gin をサーバを立ち上げようとするため、ポートの競合が発生し、デバッグモードにできない。
