import SwiftUI

// レンジの定義
struct HandRange {
    let name: String
    let hands: Set<String> // "AKs", "TT" などの文字列表現
    
    func contains(_ cards: [Card]) -> Bool {
        guard cards.count == 2 else { return false }
        let hand = HandRange.handToString(cards)
        return hands.contains(hand)
    }
    
    static func handToString(_ cards: [Card]) -> String {
        let ranks = [cards[0].rank, cards[1].rank].sorted { $0.rawValue > $1.rawValue }
        let suited = cards[0].suit == cards[1].suit
        
        if ranks[0] == ranks[1] {
            return "\(ranks[0].shortString)\(ranks[0].shortString)"
        } else {
            return "\(ranks[0].shortString)\(ranks[1].shortString)\(suited ? "s" : "o")"
        }
    }
}

class PokerGame: ObservableObject {
    @Published var hand: [Card] = []
    @Published var board: [Card] = []
    @Published var outs: Int = 0
    @Published var feedback: String = ""
    @Published var isLoading: Bool = false
    @Published var options: [Int] = []
    @Published var evaluator: PokerHandEvaluator = PokerHandEvaluator()
    @Published var selectedRange: HandRange? // 現在選択されているレンジ
    @Published var opponentRange: HandRange? // 相手のレンジ

    let suits: [Suit] = [.hearts, .spades, .diamonds, .clubs]
    let ranks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace]

    // 各ポジションのレンジ定義
    let utgRange = HandRange(
        name: "UTG Range",
        hands: Set([
            "AA", "KK", "QQ", "JJ", "TT", "99", "88", "77", "66", "55", "44", "33",
            "AKs", "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s",
            "KQs", "KJs", "KTs", "K9s", "K8s",
            "QJs", "QTs", "Q9s",
            "JTs", "J9s",
            "T9s",
            "98s", "78s",
            "AKo", "AQo", "AJo", "ATo",
            "KQo", "KJo",
            "QJo",
        ])
    )

    let btnRange = HandRange(
        name: "BTN Range",
        hands: Set([
            "AA", "KK", "QQ", "JJ", "TT", "99", "88", "77", "66", "55", "44", "33", "22",
            "AKs", "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
            "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s",
            "QJs", "QTs", "Q9s", "Q8s", "Q7s",
            "JTs", "J9s", "J8s",
            "T9s", "T8s",
            "98s", "87s", "76s", "65s", "54s", "43s", "32s",
            "AKo", "AQo", "AJo", "ATo", "A9o", "A8o",
            "KQo", "KJo", "KTo",
            "QJo", "QTo",
            "JTo"
        ])
    )

    let bbRange = HandRange(
        name: "BB Range",
        hands: Set([
            "AA", "KK", "QQ", "JJ", "TT", "99", "88", "77", "66", "55", "44", "33", "22",
            "AKs", "AQs", "AJs", "ATs", "A9s", "A8s", "A7s", "A6s", "A5s", "A4s", "A3s", "A2s",
            "KQs", "KJs", "KTs", "K9s", "K8s", "K7s", "K6s", "K5s",
            "QJs", "QTs", "Q9s", "Q8s", "Q7s",
            "JTs", "J9s", "J8s",
            "T9s", "T8s",
            "98s", "87s", "76s", "65s", "54s", "43s", "32s",
            "AKo", "AQo", "AJo", "ATo", "A9o", "A8o", "A7o", "A6o", "A5o", "A4o", "A3o", "A2o",
            "KQo", "KJo", "KTo", "K9o",
            "QJo", "QTo", "Q9o",
            "JTo", "J9o",
            "T9o"
        ])
    )

    // ランダムなボードを生成
    func startRandomBoard(position: ComboView.Position) {
        // 既存のカードをクリア
        hand.removeAll()
        board.removeAll()
        
        // ポジションに応じたレンジを設定
        switch position {
        case .utgVsBtn:
            opponentRange = utgRange  // UTGのレンジからランダムなハンドを生成
            selectedRange = btnRange  // BTNのレンジから選択する
        case .utgVsBb:
            opponentRange = utgRange  // UTGのレンジからランダムなハンドを生成
            selectedRange = bbRange   // BBのレンジから選択する
        case .btnVsBb:
            opponentRange = btnRange  // BTNのレンジからランダムなハンドを生成
            selectedRange = bbRange   // BBのレンジから選択する
        }

        // ランダムなハンドを生成（相手のレンジから）
        var deck = createDeck()
        var validHand: [Card] = []
        var attempts = 0
        let maxAttempts = 100 // 無限ループを防ぐ

        while validHand.isEmpty && attempts < maxAttempts {
            attempts += 1
            if let possibleHand = generateRandomHand(from: deck) {
                if opponentRange?.contains(possibleHand) == true {
                    validHand = possibleHand
                }
            }
        }

        if !validHand.isEmpty {
            hand = validHand
            // 使用したカードをデッキから削除
            deck.removeAll { card in validHand.contains(card) }
        } else {
            // 有効な手札が見つからない場合はデフォルトの動作
            hand = Array(deck.prefix(2))
            deck.removeFirst(2)
        }
        
        // ボードカードを生成
        for _ in 0..<5 {
            if let card = deck.randomElement() {
                board.append(card)
                deck.removeAll { $0 == card }
            }
        }
    }

    // ランダムな手札を生成するヘルパー関数
    private func generateRandomHand(from deck: [Card]) -> [Card]? {
        var tempDeck = deck
        var randomHand: [Card] = []
        
        for _ in 0..<2 {
            guard let card = tempDeck.randomElement() else { return nil }
            randomHand.append(card)
            tempDeck.removeAll { $0 == card }
        }
        
        return randomHand
    }
    
    func startGame() {
        // デフォルトのレンジを設定
        selectedRange = btnRange

        var deck = createDeck()
        hand = Array(deck.prefix(2)) // 最初の2枚を手札
        deck.removeFirst(2)
        
        board = Array(deck.prefix(3)) // 次の3枚をボード
        deck.removeFirst(3)

        outs = calculateOuts()
        feedback = ""

        var randomIndex = Int.random(in: 0..<5)
        if randomIndex > outs {
            randomIndex = 0
        }
        options = []
        for i in 0...4 {
            if i == randomIndex {
                options.append(outs)
            } else {
                options.append(outs + (i - randomIndex))
            }
        }
    }
    
    private func createDeck() -> [Card] {
        var deck: [Card] = []
        for suit in suits {
            for rank in ranks {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        deck.shuffle()
                
        return deck
    }
    
    private func calculateOuts() -> Int {
        let outs = evaluator.calculateOuts(hand: hand, board: board)
        return outs.count
    }
    
    func checkAnswer(_ answer: Int) {
        if answer == outs {
            feedback = "正解！"
            
            isLoading = true // ローディング状態を開始
            // 2秒間ローディング画面を表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                self.startGame() // 新しい問題を生成
            }
        } else {
            feedback = "不正解！(\(outs))"
        }
    }
    
    // プリフロップレンジを定義
    func isHandInRange(_ cards: [Card]) -> Bool {
        return selectedRange?.contains(cards) ?? false
    }
    
    func isHandInRange____(_ cards: [Card]) -> Bool {
        guard cards.count == 2 else { return false }
        let ranks = [cards[0].rank, cards[1].rank].sorted { $0.rawValue > $1.rawValue }
        let suited = cards[0].suit == cards[1].suit
        
        // ペア
        if ranks[0] == ranks[1] {
            return true
        }
        
        // スーテッド
        if suited {
            // AKs-A2s, KQs-K9s, QJs-Q9s, JTs-J9s, T9s-T8s, 98s, 87s, 76s, 65s
            if ranks[0] == .ace || 
               (ranks[0] == .king && ranks[1].rawValue >= Rank.nine.rawValue) ||
               (ranks[0] == .queen && ranks[1].rawValue >= Rank.nine.rawValue) ||
               (ranks[0] == .jack && ranks[1].rawValue >= Rank.nine.rawValue) ||
               (ranks[0] == .ten && ranks[1].rawValue >= Rank.eight.rawValue) ||
               (ranks[0] == .nine && ranks[1] == .eight) ||
               (ranks[0] == .eight && ranks[1] == .seven) ||
               (ranks[0] == .seven && ranks[1] == .six) ||
               (ranks[0] == .six && ranks[1] == .five) {
                return true
            }
        } else {
            // オフスーツ
            // AKo-ATo, KQo-KJo, QJo-QTo, JTo
            if (ranks[0] == .ace && ranks[1].rawValue >= Rank.ten.rawValue) ||
               (ranks[0] == .king && ranks[1].rawValue >= Rank.jack.rawValue) ||
               (ranks[0] == .queen && ranks[1].rawValue >= Rank.ten.rawValue) ||
               (ranks[0] == .jack && ranks[1] == .ten) {
                return true
            }
        }
        
        return false
    }
}
