//
//  ComboView.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/01/29.
//

import SwiftUI


struct ComboView: View {
    @StateObject private var game = PokerGame()
    @State private var selectedHands: [Hand] = []
    @State private var mode: Mode = .losing
    @State private var isInitialized: Bool = false
    @State private var resultMessage: String = ""
    @State private var hasAnswered: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showResultAnimation: Bool = false
    @State private var missedHands: Set<UUID> = []
    @State private var correctHands: Set<UUID> = []

    private let handGrid = PokerLogic.generateHandGrid()

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
                        isMissed: missedHands.contains(hand.id),
                        hasAnswered: hasAnswered,
                        isCorrectHand: correctHands.contains(hand.id),
                        isInRange: game.isHandInRange(PokerLogic.generateAllPossibleCombos(for: hand, usedCards:[])[0])
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
        // プレイヤーの手札の最高ランクを評価
        let myBestHandRank = game.evaluator.evaluateHand(cards: game.hand + game.board)
        
        // すべての可能なハンドの組み合わせを取得
        let allHands = handGrid.flatMap { $0 }
        var rangeHands: [Hand] = []
        // すでに使用されているカードを記録
        let usedCards = Set(game.board + game.hand)
        
        // 各ハンドについて、実現可能な組み合わせを確認
        for hand in allHands {
            let possibleCombos = PokerLogic.generateAllPossibleCombos(for: hand, usedCards: usedCards)
            // 実現可能な組み合わせがあり、かつレンジ内に含まれる場合
            if !possibleCombos.isEmpty && possibleCombos.contains(where: { combo in
                game.isHandInRange(combo)
            }) {
                print("hand: \(hand.name)")
                print("possibleCombos: \(possibleCombos.map { "\($0[0].str)\($0[1].str)" })")
                rangeHands.append(hand)
            }
        }
        print("rangeHands: \(rangeHands.map { $0.name })")
        
        // レンジ内のハンドから、モードに応じて勝ち/負けのコンボを抽出
        let correctHandArray = rangeHands.filter { hand in
            let possibleCombos = PokerLogic.generateAllPossibleCombos(for: hand, usedCards: usedCards)
            return possibleCombos.contains { combo in
                let rank = game.evaluator.evaluateHand(cards: combo + game.board)
                print("rank: \(rank)")
                print("combo \(combo.map { $0.str })")
                // losingモードの場合は自分より強い手、winningモードの場合は自分より弱い手を探す
                return mode == .losing ? rank > myBestHandRank : rank < myBestHandRank
            }
        }
        
        // 正解のハンドをセットとして保存
        correctHands = Set(correctHandArray.map { $0.id })
        
        // 選択されたハンドと正解のハンドを名前でセット化
        let selectedHandsSet = Set(selectedHands.map { $0.name })
        let correctHandsNameSet = Set(correctHandArray.map { $0.name })
        
        // 見逃した（選択されなかった）正解のハンドを記録
        missedHands = Set(correctHandArray.filter { !selectedHandsSet.contains($0.name) }.map { $0.id })
        
        // 選択したハンドと正解のハンドが完全に一致するか確認
        isCorrect = selectedHandsSet == correctHandsNameSet

        // 正解のコンボ数を計算
        let correctComboCount = correctHandArray.reduce(0) { count, hand in
            let possibleCombos = PokerLogic.generateAllPossibleCombos(for: hand, usedCards: usedCards)
            return count + possibleCombos.filter { combo in
                let rank = game.evaluator.evaluateHand(cards: combo + game.board)
                return mode == .losing ? rank > myBestHandRank : rank < myBestHandRank
            }.count
        }

        // レンジ内の全てのコンボ数を計算
        let totalComboCount = rangeHands.reduce(0) { count, hand in
            let possibleCombos = PokerLogic.generateAllPossibleCombos(for: hand, usedCards: usedCards)
            return count + possibleCombos.count
        }

        // 結果メッセージを設定
        resultMessage = isCorrect ? 
            "選択: \(selectedHands.count)ハンド / 正解: \(correctHandArray.count)ハンド(\(correctComboCount)/\(totalComboCount)コンボ)" :
            "選択: \(selectedHands.count)ハンド / 正解: \(correctHandArray.count)ハンド(\(correctComboCount)/\(totalComboCount)コンボ)"
        
        // 回答済みフラグを設定
        hasAnswered = true
        
        // 結果アニメーションを表示
        withAnimation {
            showResultAnimation = true
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
            missedHands = []
            correctHands = []
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
    let hasAnswered: Bool
    let isCorrectHand: Bool
    let isInRange: Bool
    
    var backgroundColor: Color {
        if hasAnswered {
            if isSelected && isCorrectHand {
                return .green     // 正解のハンドを選択
            } else if isSelected {
                return .blue      // 不正解のハンドを選択
            } else if isMissed {
                return .red       // 選択されなかった正解
            } else if !isInRange {
                return Color.gray.opacity(0.2) // レンジ外のハンド
            }
        } else if isSelected {
            return .blue      // 未回答時の選択状態
        }
        return Color.gray.opacity(0.5)  // 未選択
    }

    var body: some View {
        Text(hand.name)
            .font(.system(size: 12, weight: .bold))
            .frame(width: 30, height: 30)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
