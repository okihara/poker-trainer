import SwiftUI

class PokerGame: ObservableObject {
    @Published var hand: [Card] = []
    @Published var board: [Card] = []
    @Published var outs: Int = 0
    @Published var feedback: String = ""
    @Published var isLoading: Bool = false // ローディング状態を管理
    @Published var options: [Int] = []
    @Published var evaluator: PokerHandEvaluator = PokerHandEvaluator()
    
    let suits: [Suit] = [.hearts, .spades, .diamonds, .clubs]
    let ranks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace]
    
    func startGame() {
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
    
    func startFromRiver() {
        var deck = createDeck()
        hand = Array(deck.prefix(2)) // 最初の2枚を手札
        deck.removeFirst(2)
        
        board = Array(deck.prefix(5))
        deck.removeFirst(5)

        feedback = ""
    }
    
    func startRandomBoard() {
        // デッキをリセット
        var deck = createDeck()
        
        // ボードのカード枚数をランダムに決定（3-5枚）
        let boardCount = Int.random(in: 3...5)
        
        // ボードカードを上から選択
        board = Array(deck.prefix(boardCount))
        deck.removeFirst(boardCount)
        
        // レンジに合う手札が見つかるまで探す
        var validHand: [Card] = []
        while validHand.isEmpty {
            let card1Index = Int.random(in: 0..<deck.count)
            let card1 = deck[card1Index]
            let card2Index = Int.random(in: 0..<deck.count)
            let card2 = deck[card2Index]
            
            if card1Index != card2Index && isHandInRange([card1, card2]) {
                validHand = [card1, card2]
                deck.remove(at: max(card1Index, card2Index))
                deck.remove(at: min(card1Index, card2Index))
            }
        }
        
        hand = validHand
    }
    
    // プリフロップレンジを定義
    func isHandInRange(_ cards: [Card]) -> Bool {
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
    
    private func createDeck() -> [Card] {
        var deck: [Card] = []
        for suit in suits {
            for rank in ranks {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        deck.shuffle()
        
        // レンジに合う手札が見つかるまで探す
        var validHand: [Card] = []
        var i = 0
        while i < deck.count - 1 {
            if isHandInRange([deck[i], deck[i + 1]]) {
                validHand = [deck[i], deck[i + 1]]
                deck.remove(at: i + 1)
                deck.remove(at: i)
                break
            }
            i += 1
        }
        
        return validHand + deck
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
} 
