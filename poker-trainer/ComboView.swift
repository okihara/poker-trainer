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
    @State private var selectedHands: [Hand] = []
    @StateObject private var game = PokerGame()
    @State private var mode: Mode = .losing
    @State private var isInitialized: Bool = false
    @State private var resultMessage: String = ""
    @State private var hasAnswered: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showResultAnimation: Bool = false
    @State private var missedHands: Set<UUID> = []

    private let handGrid = generateHandGrid()

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
                VStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isCorrect ? .green : .red)
                        .scaleEffect(showResultAnimation ? 1.0 : 0.1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showResultAnimation)
                    
                    Text(resultMessage)
                        .font(.headline)
                        .foregroundColor(isCorrect ? .green : .red)
                        .padding()
                        .opacity(showResultAnimation ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.2).delay(0.3), value: showResultAnimation)
                }
            }
            
            // モード切り替えボタンと回答/次へボタン
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
                .disabled(hasAnswered) // 回答後は無効化

                Button(action: {
                    mode = .losing
                }) {
                    Text("負けてるコンボ")
                        .padding()
                        .background(mode == .losing ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(hasAnswered) // 回答後は無効化

                if !hasAnswered {
                    Button(action: {
                        checkAnswer()
                        hasAnswered = true // 回答済みにする
                    }) {
                        Text("回答")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        nextProblem()
                    }) {
                        Text("次へ")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }

            // グリッド表示
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 13), spacing: 4) {
                ForEach(handGrid.flatMap { $0 }) { hand in
                    HandCell(
                        hand: hand,
                        isSelected: selectedHands.contains(where: { $0.id == hand.id }),
                        isMissed: missedHands.contains(hand.id)
                    )
                    .onTapGesture {
                        if !hasAnswered {
                            toggleHandSelection(hand)
                        }
                    }
                }
            }
            .padding(.top, 5)
        }
        .onAppear {
            if !isInitialized {
                isInitialized = true
                game.startFromRiver()
            }
        }
    }
    
    // 回答ボタンのアクション
    private func checkAnswer() {
        let myBestHandRank = game.evaluator.evaluateHand(cards: game.hand + game.board)

        // 正解のコンボを計算
        let allHands = handGrid.flatMap { $0 }
        let correctHands = allHands.filter { hand in
            let rank = game.evaluator.evaluateHand(cards: generateCardsForHand(hand) + game.board)
            return mode == .losing ? rank > myBestHandRank : rank < myBestHandRank
        }

        let selectedHandsSet = Set(selectedHands.map { $0.name })
        let correctHandsSet = Set(correctHands.map { $0.name })
        
        // 選択されていない正解のハンドを記録
        missedHands = Set(correctHands.filter { !selectedHandsSet.contains($0.name) }.map { $0.id })
        
        isCorrect = selectedHandsSet == correctHandsSet
        
        resultMessage = isCorrect ? 
            "選択: \(selectedHands.count)コンボ / 正解: \(correctHands.count)コンボ" :
            "選択: \(selectedHands.count)コンボ / 正解: \(correctHands.count)コンボ"
        
        hasAnswered = true
        
        withAnimation {
            showResultAnimation = true
        }
    }

    // ハンドのカードを生成する仮の関数
    private func generateCardsForHand(_ hand: Hand) -> [Card] {
        let name = hand.name
        
        // スーテッドかオフスーテッドかを判定
        let isSuited = name.hasSuffix("s")
        
        // カードのランクを取得
        let rankChars = Array(name.prefix(2))
        guard rankChars.count == 2,
              let firstRank = Rank(String(rankChars[0])),
              let secondRank = Rank(String(rankChars[1])) else {
            return []
        }
        
        // スーテッドの場合は同じスート、オフスーテッドの場合は異なるスートを使用
        if isSuited {
            return [
                Card(rank: firstRank, suit: .spades),
                Card(rank: secondRank, suit: .spades)
            ]
        } else {
            return [
                Card(rank: firstRank, suit: .spades),
                Card(rank: secondRank, suit: .hearts)
            ]
        }
    }

    // ハンド選択/解除の切り替え
    private func toggleHandSelection(_ hand: Hand) {
        if let index = selectedHands.firstIndex(where: { $0.id == hand.id }) {
            selectedHands.remove(at: index) // 既に選択されていれば解除
        } else {
            selectedHands.append(hand) // 新しく選択
        }
    }

    // 次の問題へ進むメソッド
    private func nextProblem() {
        withAnimation {
            showResultAnimation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedHands = []
            missedHands = [] // missedHandsをリセット
            resultMessage = ""
            hasAnswered = false
            isCorrect = false
            game.startFromRiver()
        }
    }
}

// 個別ハンドセルのビュー
struct HandCell: View {
    let hand: Hand
    let isSelected: Bool
    let isMissed: Bool

    var body: some View {
        Text(hand.name)
            .font(.system(size: 12, weight: .bold))
            .frame(width: 30, height: 30)
            .background(
                isMissed ? Color.red :
                isSelected ? Color.blue :
                Color.gray.opacity(0.5)
            )
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
