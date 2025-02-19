# ポーカートレーナー

このアプリケーションは、ポーカープレイヤーのスキル向上を支援するためのトレーニングツールです。

## 機能

- ポットオッズトレーニング機能
- ハンドコンボの表示と学習機能
- ポーカーゲームのシミュレーション

## 技術スタック

- SwiftUI - モダンなUIフレームワーク
- Swift - メインのプログラミング言語
- XCode - 開発環境

## プロジェクト構成

```
poker-trainer/
├── poker-trainer/          # メインアプリケーションコード
│   ├── poker_trainerApp.swift  # アプリケーションのエントリーポイント
│   ├── ContentView.swift       # メインビュー
│   ├── PotOddsTrainerView.swift # ポットオッズトレーニング機能
│   ├── ComboView.swift         # ハンドコンボ表示機能
│   └── PokerGame.swift         # ゲームロジック
├── poker-trainer.xcodeproj/    # XCodeプロジェクトファイル
└── logic-test/                 # テストコード
```

## 開発環境のセットアップ

1. XCodeをインストール（最新版推奨）
2. リポジトリをクローン
3. `poker-trainer.xcodeproj`を開く
4. ビルドして実行

## ライセンス

このプロジェクトは独自のライセンスで保護されています。
