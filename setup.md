---
marp: true
theme: default
paginate: true

---

![bg right:33% width:650](./res/undraw_Online_world_re_h4cb.png)

# Flutter ✕ Livekit でオンライン会議アプリを作る


---
# アジェンダ
  - 自己紹介
  - 開発環境
  - 今回作るもの
  - 手順解説


---
# 自己紹介
  - C#でWindowsアプリケーションを作っている田舎のサラリーマン

---
# 開発環境など
  - MacOS：12.2.1
  - Flutter：Version 3.0.1
  - Ubuntu22.04 LTS (さくらのVPS)

---
# 今回つくるもの

---
# 大まかな手順

- サーバの構築1(Livekitサーバ)
- サーバの構築2(Token処理サーバ)
- クライアントアプリの作成(Flutterアプリ)

## 重要：セキュリティ対策などはご自身で実施をお願いします。

---
# サーバの構築1(Livekitサーバ)の流れ

- dockerを使えるようにする
- LivekitのConfigファイルを生成する
- Livekitサーバを建てる

---
# サーバの構築1-1(Livekitサーバ)
  - 作業ディレクトリに移動しておく
    - `sudo mkdir /srv/livekit`
    - `cd /srv/livekit`
  - dockerを使えるようにする
    - `sudo apt-get update`
    - `sudo apt-get upgrade`
    - `sudo apt-get install docker docker-compose`
  
---
# サーバの構築1-2(Livekitサーバ) 
- LivekitのConfigファイルを生成する
    - `sudo docker run --rm -v$PWD:/output livekit/generate --local`
```bash
Unable to find image 'livekit/generate:latest' locally
--中略--
Generated livekit.yaml that's suitable for local testing

Start LiveKit with:
docker run --rm \
    -p 7880:7880 \
    -p 7881:7881 \
    -p 7882:7882/udp \
    -v $PWD/livekit.yaml:/livekit.yaml \
    livekit/livekit-server \
    --config /livekit.yaml \
    --node-ip=127.0.0.1

Note: --node-ip needs to be reachable by the client. 127.0.0.1 is accessible only to the current machine

Server URL:  ws://localhost:7880
API Key: XXX
API Secret: YYY

Here's a test token generated with your keys: ZZZ
```  
`API Key`と`API Secret`はメモしておくこと

---
# サーバの構築1-3(Livekitサーバ) 
  - Livekitサーバを建てる
```bash
sudo docker run -d --rm -p 7880:7880 \
    -p 7881:7881 \
    -p 7882:7882/udp \
    -v $PWD/livekit.yaml:/livekit.yaml \
    livekit/livekit-server \
    --config /livekit.yaml \
    --node-ip <machine-ip>
```

※<machine-ip>はローカルで試す場合は`127.0.0.1`など。VPSで試す場合はグローバルIPアドレスを指定する。ドメインを使ってもいい(これが普通)。

---
# サーバの構築2(Token処理サーバ)の流れ

- nodejsの実行環境をインストール
- nodejsアプリの作成と、必要モジュールのインストール
- livekit-server-sdkを使い、Tokenを生成しクライアントに返却するサーバを作成
- nodejsアプリを実行

---
# サーバの構築2-1(Token処理サーバ)

* nodejsの実行環境をインストール

```bash
# node.jsとnpmをインストール
sudo apt-get install nodejs npm

# node.jsを最新にするためのnコマンドのインストール
sudo npm install n -g

 # nコマンドでnodejs, npmのLTS版をインストールする
sudo n lts

# バージョン確認
node -v
v16.15.1
```

---
# サーバの構築2-2(Token処理サーバ)

* nodejsアプリの作成と、必要モジュールのインストール

```bash
# Token処理サーバを作るディレクトリを作成
sudo mkdir /srv/token-server

# 移動して、nodeプロジェクトを作成
cd /srv/token-server
sudo npm init -y

#livekitSDK、express(webアプリ作成フレームワーク)、body-parserをインストール
sudo npm install livekit-server-sdk --save
sudo npm install express
sudo npm install body-parser

# app.jsを作っておく
sudo touch app.js
```

---
# サーバの構築2-3(Token処理サーバ)

* livekit-server-sdkを使い、Tokenを生成しクライアントに返却するサーバを作成

```javascript
// app.jsの中身

// Import Modules
const express = require('express');
const bodyParser = require('body-parser');
const livekitApi = require('livekit-server-sdk');
const AccessToken = livekitApi.AccessToken;
const RoomServiceClient = livekitApi.RoomServiceClient;

// Constants
const PORT = 3000;
const HOST = '0.0.0.0';
const API_KEY = "XXX";
const SECRET_KEY = "YYY";

// App
const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.post('/token', (req, res) => {
  const roomName = req.body.roomName;
  const participantName = req.body.userName;

  const at = new AccessToken(API_KEY, SECRET_KEY, {
    identity: participantName,
  });
  at.addGrant({ roomJoin: true, room: roomName });
  const token = at.toJwt();

  res.send(token);
});

app.listen(PORT, HOST);
```

---
# サーバの構築2-4(Token処理サーバ)

* nodejsアプリを実行

```bash
sudo node app.js
```
完了。

必要に応じてバックグラウンド実行や、サービス化をしておくと良い。


---
# クライアントの作成(Flutter)

公式Exampleをカスタマイズする

| 変更前                                                                 | 変更後                                                                 |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| ![height:400](./res/%E5%A4%89%E6%9B%B4%E5%89%8D%E7%94%BB%E9%9D%A2.png) | ![height:400](./res/%E5%A4%89%E6%9B%B4%E5%BE%8C%E7%94%BB%E9%9D%A2.png) |

---
# クライアントの作成(Flutter)

* 公式リポジトリをfork：[fork後のリポジトリ](https://github.com/morio77/client-sdk-flutter-example-test)
* `Example`を改造していく：[改造後ソース](https://github.com/morio77/client-sdk-flutter-example-test/tree/main/example/lib)
  - Token取得クラス
  - ユーザ名入力域
  - ルーム選択ボタン
  - 接続ボタン
    - ルームに接続する