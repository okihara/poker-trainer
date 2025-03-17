//
//  TextureViewModel.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/03/17.
//

import Foundation

class TextureViewModel: ObservableObject {
    @Published var game: PokerGame = PokerGame()

    @Published var isLoading: Bool = false
    @Published var feedback: String = ""
    @Published var hand: [Card] = []
    @Published var board: [Card] = []
    
    // テクスチャー判断用の変数
    @Published var selectedSuitTexture: SuitTexture?
    @Published var selectedConnectTexture: ConnectTexture?
    @Published var selectedPairTexture: PairTexture?
    @Published var selectedHighCardTexture: HighCardTexture?
    @Published var selectedEquity: Double? // ユーザーが選択した勝率
    @Published var isCorrect: Bool = false // 正解かどうか
    @Published var showNextButton: Bool = false // 次の問題へボタンを表示するかどうか
    
    // 必要勝率判断用の変数
    @Published var potSize: Double = 5600.0 // ポットサイズ（固定）
    @Published var betSize: Double = 0.0 // ベットサイズ
    @Published var requiredEquity: Double = 0.0 // 必要な勝率
    @Published var equityOptions: [Double] = [0.16, 0.20, 0.25, 0.33, 0.40] // 選択肢

    // テクスチャー判断用の列挙型
    enum SuitTexture: String, CaseIterable, Identifiable {
        case rainbow = "レインボー"
        case twoTone = "ツートーン"
        case monotone = "モノトーン"
        
        var id: String { self.rawValue }
    }

    enum ConnectTexture: String, CaseIterable, Identifiable {
        case disconnected = "非コネクト"
        case gutShotDraw = "ガットあり"
        case openEndedDraw = "OESDあり"
        case connected = "コネクト"
        
        var id: String { self.rawValue }
    }

    enum PairTexture: String, CaseIterable, Identifiable {
        case noPair = "ペアなし"
        case paired = "ペアあり"
        case trips = "トリプル"
        
        var id: String { self.rawValue }
    }

    enum HighCardTexture: String, CaseIterable, Identifiable {
        case aceHigh = "Aハイ"
        case kqHigh = "K/Qハイ"
        case jOrLower = "Jハイ以下"
        
        var id: String { self.rawValue }
    }
    
    func getBoard() -> [Card] {
        return game.board
    }

    // テクスチャー判断機能
    func startTextureGame() {
        isLoading = false
        feedback = ""
        showNextButton = false
        
        // 選択をリセット
        selectedSuitTexture = nil
        selectedConnectTexture = nil
        selectedPairTexture = nil
        selectedHighCardTexture = nil
        selectedEquity = nil
        
        var deck = game.createDeck()
        hand = Array(deck.prefix(2)) // 最初の2枚を手札
        deck.removeFirst(2)
        
        board = Array(deck.prefix(3)) // 次の3枚をボード
        deck.removeFirst(3)
        
        // 必要勝率の計算
        // ポットサイズは固定
        potSize = 5600.0
        
        // ベットサイズはポットサイズの20%, 33%, 50%, 75%のいずれかに少し揺らぎを持たせる
        let betSizePercentages = [0.2, 0.33, 0.5, 0.75]
        let selectedPercentage = betSizePercentages.randomElement() ?? 0.5
        
        // 揺らぎを追加（選択した割合の±5%）
        let variation = Double.random(in: -0.05...0.05)
        let finalPercentage = selectedPercentage + variation
        
        // ベットサイズを計算（小数点以下を切り捨て）
        betSize = floor(potSize * finalPercentage)
        betSize = ceil(betSize / 100) * 100
        
        // 必要勝率を計算
        requiredEquity = betSize / (potSize + betSize * 2)
    }
    
    // テクスチャー判断の正解を計算
    func getCorrectSuitTexture() -> SuitTexture {
        let suits = Set(board.map { $0.suit })
        switch suits.count {
        case 1:
            return .monotone
        case 2:
            return .twoTone
        case 3:
            return .rainbow
        default:
            return .rainbow
        }
    }
    
    func getCorrectConnectTexture() -> ConnectTexture {
        // 重複を排除したランクの配列を作成
        let ranks = Array(Set(board.map { $0.rank.rawValue })).sorted()
        
        // 通常のケース（Aを14として扱う）
        let result = evaluateConnectedness(ranks: ranks)
        if result != .disconnected {
            return result
        }
        
        // エースを1としても確認（A, 2, 3などの場合）
        if ranks.contains(14) { // Aが含まれている場合
            var modifiedRanks = Array(Set(ranks.filter { $0 != 14 } + [1])) // Aを除外し、Aを1として追加
            modifiedRanks.sort()
            
            let resultWithAceAsOne = evaluateConnectedness(ranks: modifiedRanks)
            if resultWithAceAsOne != .disconnected {
                return resultWithAceAsOne
            }
        }
        
        return .disconnected
    }
    
    func getCorrectPairTexture() -> PairTexture {
        let rankCounts = Dictionary(grouping: board, by: { $0.rank }).mapValues { $0.count }
        
        if rankCounts.values.contains(3) {
            return .trips
        } else if rankCounts.values.contains(2) {
            return .paired
        } else {
            return .noPair
        }
    }
    
    func getCorrectHighCardTexture() -> HighCardTexture {
        let highestRank = board.map { $0.rank.rawValue }.max() ?? 0
        
        if highestRank == 14 { // A
            return .aceHigh
        } else if highestRank >= 12 { // K or Q
            return .kqHigh
        } else {
            return .jOrLower
        }
    }
    
    func getCorrectEquity() -> Double {
        // 最も近い選択肢を正解とする
        return equityOptions.min(by: { abs($0 - requiredEquity) < abs($1 - requiredEquity) }) ?? 0.0
    }
    
    func checkTextureAnswer() -> Bool {
        let correctSuit = getCorrectSuitTexture()
        let correctConnect = getCorrectConnectTexture()
        let correctPair = getCorrectPairTexture()
        let correctHighCard = getCorrectHighCardTexture()
        let correctEquity = getCorrectEquity()
        
        let isCorrect = selectedSuitTexture == correctSuit &&
                        selectedConnectTexture == correctConnect &&
                        selectedPairTexture == correctPair &&
                        selectedHighCardTexture == correctHighCard &&
                        selectedEquity == correctEquity
        
        self.isCorrect = isCorrect
        
        if isCorrect {
            feedback = "正解！\n\(correctSuit.rawValue), \(correctConnect.rawValue), \(correctPair.rawValue), \(correctHighCard.rawValue), 必要勝率: \(Int(correctEquity * 100))%"

            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isLoading = false
                self.startTextureGame() // 新しい問題を生成
            }
        } else {
            feedback = "不正解！\n正解: \(correctSuit.rawValue), \(correctConnect.rawValue), \(correctPair.rawValue), \(correctHighCard.rawValue), 必要勝率: \(Int(correctEquity * 100))%"
            showNextButton = true // 次の問題へボタンを表示
        }
        
        return isCorrect
    }
    
    // 次の問題へ進む
    func nextTextureQuestion() {
        showNextButton = false
        startTextureGame()
    }
    
    // 隣接する数字間のギャップを計算する関数
    private func calculateGaps(ranks: [Int]) -> [Int] {
        var gaps: [Int] = []
        for i in 0..<ranks.count-1 {
            gaps.append(ranks[i+1] - ranks[i] - 1)
        }
        print("gaps: \(gaps)")        
        return gaps
    }
    
    // ギャップに基づいてコネクトネスを評価する関数
    private func evaluateConnectedness(ranks: [Int]) -> ConnectTexture {
        let gaps = calculateGaps(ranks: ranks)

        // ボードに3枚以上のカードがある場合のみ評価
        if gaps.count >= 2 {
            // 全てのギャップの合計が2以下ならconnected
            let totalGap = gaps.reduce(0, +)
            if totalGap <= 2 {
                return .connected
            }
            
            // 隣接する2枚のカードのギャップが2以下ならopenEndedDraw
            for gap in gaps {
                if gap <= 2 {
                    if ranks.contains(14) || ranks.contains(1) {
                        return .gutShotDraw
                    } else {
                        return .openEndedDraw
                    }
                }
            }
        } else if gaps.count == 1 {
            // ボードに2枚のカードしかない場合
            if gaps[0] <= 2 {
                return .openEndedDraw
            }
        }
        
        return .disconnected
    }
}
