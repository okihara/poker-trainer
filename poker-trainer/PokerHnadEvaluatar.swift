//
//  PokerHnadEvaluatar.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/01/26.
//

import Foundation

enum Suit: String {
    case hearts = "H"
    case diamonds = "D"
    case clubs = "C"
    case spades = "S"
}

enum Rank: Int, Comparable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
    case ace = 14

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    init?(_ string: String) {
        switch string.uppercased() {
        case "A": self = .ace
        case "K": self = .king
        case "Q": self = .queen
        case "J": self = .jack
        case "T": self = .ten
        case "9": self = .nine
        case "8": self = .eight
        case "7": self = .seven
        case "6": self = .six
        case "5": self = .five
        case "4": self = .four
        case "3": self = .three
        case "2": self = .two
        default:
            return nil
        }
    }
}

struct Card: Comparable, Hashable {
    let rank: Rank
    let suit: Suit

    static func < (lhs: Card, rhs: Card) -> Bool {
        return lhs.rank < rhs.rank
    }
    
    // ファイル名を取得
    var imageName: String {
        var s = ""
        switch suit {
        case .hearts:
            s = "hearts"
        case .spades:
            s = "spades"
        case .clubs:
            s = "clubs"
        case .diamonds:
            s = "diamonds"
        }
        
        var r = ""
        switch rank {
        case .jack:
            r = "jack"
        case .queen:
            r = "queen"
        case .king:
            r = "king"
        case .ace:
            r = "ace"
        default:
            r = String(format: "%02d", rank.rawValue)
        }
        
        return "\(s)_\(r)"
    }

    var str: String {
        var rankStr: String
        switch rank {
        case .ace:
            rankStr = "A"
        case .king:
            rankStr = "K"
        case .queen:
            rankStr = "Q"
        case .jack:
            rankStr = "J"
        default:
            rankStr = String(rank.rawValue)
        }
        
        var suitStr: String
        switch suit {
        case .hearts:
            suitStr = "❤︎"
        case .spades:
            suitStr = "♠︎"
        case .clubs:
            suitStr = "♣︎"
        case .diamonds:
            suitStr = "♦︎"
        }
        
        return "\(rankStr)\(suitStr)"
    }
}

struct HandRank: Comparable {
    let rankType: RankType
    let ranks: [Rank]

    enum RankType: Int {
        case highCard = 1
        case onePair
        case twoPair
        case threeOfAKind
        case straight
        case flush
        case fullHouse
        case fourOfAKind
        case straightFlush
        case royalFlush
    }

    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.rankType.rawValue != rhs.rankType.rawValue {
            return lhs.rankType.rawValue < rhs.rankType.rawValue
        }
        // 同じ役の場合、カードのランクで比較
        for (lRank, rRank) in zip(lhs.ranks, rhs.ranks) {
            if lRank != rRank {
                return lRank < rRank
            }
        }
        return false
    }
}

class PokerHandEvaluator {
    func evaluateHand(cards: [Card]) -> HandRank {
        guard cards.count >= 4 else {
            fatalError("カードの枚数は4枚以上である必要があります")
        }

        let sortedCards = cards.sorted()
        let isFlush = checkFlush(cards: sortedCards)
        let isStraight = checkStraight(cards: sortedCards)

        if isFlush && isStraight && sortedCards.last?.rank == .ace {
            return HandRank(rankType: .royalFlush, ranks: sortedCards.map { $0.rank })
        } else if isFlush && isStraight {
            return HandRank(rankType: .straightFlush, ranks: sortedCards.map { $0.rank })
        } else if let fourOfAKindRanks = checkFourOfAKind(cards: sortedCards) {
            return HandRank(rankType: .fourOfAKind, ranks: fourOfAKindRanks)
        } else if let fullHouseRanks = checkFullHouse(cards: sortedCards) {
            return HandRank(rankType: .fullHouse, ranks: fullHouseRanks)
        } else if isFlush {
            return HandRank(rankType: .flush, ranks: sortedCards.map { $0.rank })
        } else if isStraight {
            return HandRank(rankType: .straight, ranks: sortedCards.map { $0.rank })
        } else if let threeOfAKindRanks = checkThreeOfAKind(cards: sortedCards) {
            return HandRank(rankType: .threeOfAKind, ranks: threeOfAKindRanks)
        } else if let twoPairRanks = checkTwoPair(cards: sortedCards) {
            return HandRank(rankType: .twoPair, ranks: twoPairRanks)
        } else if let onePairRanks = checkOnePair(cards: sortedCards) {
            return HandRank(rankType: .onePair, ranks: onePairRanks)
        } else {
            return HandRank(rankType: .highCard, ranks: sortedCards.map { $0.rank })
        }
    }

    func calculateOuts(hand: [Card], board: [Card]) -> [Card] {
        guard hand.count == 2, board.count == 3 else {
            fatalError("手札は2枚、ボードは3枚である必要があります")
        }

        print("=========================================")
        print(hand.map {$0.str}.joined())
        print(board.map {$0.str}.joined())

        let deck = createDeck(excluding: hand + board)
        var outsSet = Set<Card>()
        for card in deck {
            let handAndBoardRank = evaluateHand(cards: hand + board)
            let newBoard = board + [card]
            let newBoardRank = evaluateHand(cards: newBoard)
            let newBoardAndHandRank = evaluateHand(cards: newBoard + hand)

            // ターンの6枚の役がフロップの5枚の役より強かったらアウツになりえる
            if newBoardAndHandRank > handAndBoardRank {
                print("************")
                print("\(card.str): \(newBoardAndHandRank.rankType) > \(handAndBoardRank.rankType)")
                // ボードだけの役より強い場合のみアウツに
                if newBoardAndHandRank > newBoardRank {
                    print("\(card.str): \(newBoardAndHandRank.rankType) > \(newBoardRank.rankType)")

                    if newBoardAndHandRank.rankType == .twoPair {
                        let contains = hand.map {$0.rank}.contains(card.rank)

                        print("contains:\(contains)")
                        if !contains {
                            continue
                        }
                    }
                    print("アウツ: \(card.str) ")
                    outsSet.insert(card)
                }
            }
        }

        return Array(outsSet)
    }

    private func createDeck(excluding cards: [Card]) -> [Card] {
        let allSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        let allRanks: [Rank] = [.two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace]

        var deck: [Card] = []
        for suit in allSuits {
            for rank in allRanks {
                let card = Card(rank: rank, suit: suit)
                if !cards.contains(card) {
                    deck.append(card)
                }
            }
        }
        return deck
    }

    private func isBackdoorDraw(hand: [Card], board: [Card]) -> Bool {
        // フラッシュバックドアのチェック
        let suits = hand.map { $0.suit } + board.map { $0.suit }
        let suitCounts = Dictionary(grouping: suits, by: { $0 }).mapValues { $0.count }
        if suitCounts.values.contains(4) {
            return true
        }

        // ストレートバックドアのチェック
        let ranks = Array(Set(hand.map { $0.rank.rawValue } + board.map { $0.rank.rawValue })).sorted()
        for i in 0..<(ranks.count - 3) {
            if ranks[i...i+3].enumerated().allSatisfy({ $0.element == ranks[i] + $0.offset }) {
                return true
            }
        }

        return false
    }

    private func checkFlush(cards: [Card]) -> Bool {
        let suitCounts = Dictionary(grouping: cards, by: { $0.suit }).mapValues { $0.count }
        return suitCounts.values.contains(where: { $0 >= 5 })
    }

    private func checkStraight(cards: [Card]) -> Bool {
        let sortedRanks = cards.map { $0.rank.rawValue }.sorted()

        // 通常のストレートチェック
        for i in 0..<(sortedRanks.count - 4) {
            if sortedRanks[i] + 1 == sortedRanks[i + 1],
               sortedRanks[i + 1] + 1 == sortedRanks[i + 2],
               sortedRanks[i + 2] + 1 == sortedRanks[i + 3],
               sortedRanks[i + 3] + 1 == sortedRanks[i + 4] {
                return true
            }
        }

        // A-2-3-4-5のストレートチェック
        let aceLowStraight = [Rank.ace.rawValue, Rank.two.rawValue, Rank.three.rawValue, Rank.four.rawValue, Rank.five.rawValue]
        if Set(sortedRanks).isSuperset(of: Set(aceLowStraight)) {
            return true
        }

        return false
    }

   private func checkFourOfAKind(cards: [Card]) -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
        if let fourRank = rankCounts.first(where: { $0.value == 4 })?.key {
            let remainingRanks = cards.filter { $0.rank != fourRank }.map { $0.rank }
            return [fourRank] + remainingRanks
        }
        return nil
    }

    private func checkFullHouse(cards: [Card]) -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value } // カウントの多い順にソート
        
        // スリーカードを探す
        guard let threeOfAKind = rankCounts.first(where: { $0.value >= 3 }) else {
            return nil
        }
        
        // 残りのカードからペアを探す（スリーカードと異なるランクのみ）
        let remainingPairs = rankCounts.filter { $0.key != threeOfAKind.key && $0.value >= 2 }
        
        if let pair = remainingPairs.first {
            return [threeOfAKind.key, pair.key]
        }
        
        return nil
    }

    private func checkThreeOfAKind(cards: [Card]) -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
        if let threeRank = rankCounts.first(where: { $0.value == 3 })?.key {
            let remainingRanks = cards.filter { $0.rank != threeRank }.map { $0.rank }
            return [threeRank] + remainingRanks
        }
        return nil
    }

    private func checkTwoPair(cards: [Card]) -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
        let pairs = rankCounts.filter { $0.value == 2 }.keys.sorted(by: >)
        if pairs.count >= 2 {
            let remainingRanks = cards.filter { !pairs.contains($0.rank) }.map { $0.rank }
            return Array(pairs.prefix(2)) + remainingRanks
        }
        return nil
    }

    private func checkOnePair(cards: [Card]) -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank }).mapValues { $0.count }
        if let pairRank = rankCounts.first(where: { $0.value == 2 })?.key {
            let remainingRanks = cards.filter { $0.rank != pairRank }.map { $0.rank }
            return [pairRank] + remainingRanks
        }
        return nil
    }
}
