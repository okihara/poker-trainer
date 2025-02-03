//
//  ComboView.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/01/29.
//

import SwiftUI


// ハンドのデータモデル
struct Hand: Identifiable {
    let id = UUID()
    let name: String // 例: "AKs", "AKo", "QQ"
    let type: HandType
}

enum HandType {
    case suited, offsuit, pair
}

// デモ用のハンドデータを生成
func generateHandGrid() -> [[Hand]] {
    let ranks = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
    var grid: [[Hand]] = []

    for i in 0..<13 {
        var row: [Hand] = []
        for j in 0..<13 {
            if i == j {
                row.append(Hand(name: "\(ranks[i])\(ranks[j])", type: .pair)) // ポケットペア
            } else if i < j {
                row.append(Hand(name: "\(ranks[i])\(ranks[j])s", type: .suited)) // スーテッド
            } else {
                row.append(Hand(name: "\(ranks[j])\(ranks[i])o", type: .offsuit)) // オフスート
            }
        }
        grid.append(row)
    }
    return grid
}

struct ComboView: View {
    @State private var selectedHands: [Hand] = [] // 選択済みのハンドを保持
    @StateObject private var game = PokerGame()
    @State private var mode: Mode = .losing // 現在のモード
    @State private var isInitialized: Bool = false // 初期化フラグ
    @State private var resultMessage: String = "" // 結果メッセージ

    private let handGrid = generateHandGrid() // ハンドのグリッドデータ

    enum Mode {
        case winning, losing
    }
    


    var body: some View {
        VStack {
            HStack {
                ForEach(game.board, id: \.self) { card in
                    Image(card.imageName)
                        .resizable()
                        .frame(width: 40, height: 60)
                        .shadow(radius: 4)
                }
            }.padding(.top, 20)
            
            HStack {
                ForEach(game.hand, id: \.self) { card in
                    Image(card.imageName)
                        .resizable()
                        .frame(width: 40, height: 60)
                        .shadow(radius: 4)
                }
            }
            .padding()

            // 結果メッセージの表示
            if !resultMessage.isEmpty {
                Text(resultMessage)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            }
            
            // モード切り替えボタン
            HStack {
                Button(action: {
                    mode = .winning
                }) {
                    Text("勝ってるコンボ")
                        .padding()
                        .background(mode == .winning ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    mode = .losing
                }) {
                    Text("負けてるコンボ")
                        .padding()
                        .background(mode == .losing ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    // clearSelectedHands()
                    checkAnswer()

                }) {
                    Text("回答")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
//            .padding()

            // グリッド表示
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 13), spacing: 4) {
                ForEach(handGrid.flatMap { $0 }) { hand in
                    HandCell(hand: hand, isSelected: selectedHands.contains(where: { $0.id == hand.id }))
                        .onTapGesture {
                            toggleHandSelection(hand)
                        }
                }
            }
            .padding(.top, 5)

//            // 選択済みハンドのリスト
//            VStack(alignment: .leading) {
//                Text("選択済みのハンド:")
//                    .font(.headline)
//                    .padding(.top)
//
//                ScrollView {
//                    ForEach(selectedHands) { hand in
//                        Text(hand.name)
//                            .padding(4)
//                            .background(Color.gray.opacity(0.2))
//                            .cornerRadius(4)
//                    }
//                }
//            }
//            .padding()
        }
        .onAppear {
            if !isInitialized {
                isInitialized = true
                game.startFromRiver()
            }
        }
    }
    
    private func clearSelectedHands() {
        selectedHands = []
        game.startFromRiver()
    }

        // 回答ボタンのアクション
    private func checkAnswer() {
        game.startFromRiver()
        let myBestHandRank = game.evaluator.evaluateHand(cards: game.hand + game.board)
        let selectedHandsRanks = selectedHands.map { hand in
            // 仮のロジック: 各ハンドの役を評価
            // 実際には、ハンドのカードを生成して評価する必要があります
            return game.evaluator.evaluateHand(cards: generateCardsForHand(hand) + game.board)
        }

        if selectedHandsRanks.allSatisfy({ $0 > myBestHandRank }) {
            resultMessage = "正解！選択したハンドはすべてあなたのハンドより強いです。"
        } else {
            resultMessage = "不正解。選択したハンドの中にあなたのハンドより弱いものがあります。"
        }
    }

    // ハンドのカードを生成する仮の関数
    private func generateCardsForHand(_ hand: Hand) -> [Card] {
        // ここでHandのnameを解析してCardの配列を生成するロジックを実装
        // 例: "AKs" -> [Card(rank: .ace, suit: .spades), Card(rank: .king, suit: .spades)]
        return []
    }

    // ハンド選択/解除の切り替え
    private func toggleHandSelection(_ hand: Hand) {
        if let index = selectedHands.firstIndex(where: { $0.id == hand.id }) {
            selectedHands.remove(at: index) // 既に選択されていれば解除
        } else {
            selectedHands.append(hand) // 新しく選択
        }
    }
}

// 個別ハンドセルのビュー
struct HandCell: View {
    let hand: Hand
    let isSelected: Bool

    var body: some View {
        Text(hand.name)
            .font(.system(size: 12, weight: .bold))
            .frame(width: 30, height: 30)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
