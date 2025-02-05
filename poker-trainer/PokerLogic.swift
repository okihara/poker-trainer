import Foundation

// ハンドのデータモデル
struct Hand: Identifiable {
    let id = UUID()
    let name: String
    let type: HandType
}

enum HandType {
    case suited, offsuit, pair
}

class PokerLogic {
    // デモ用のハンドデータを生成
    static func generateHandGrid() -> [[Hand]] {
        let ranks = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
        var grid: [[Hand]] = []

        for i in 0..<13 {
            var row: [Hand] = []
            for j in 0..<13 {
                if i == j {
                    row.append(Hand(name: "\(ranks[i])\(ranks[j])", type: .pair))
                } else if i < j {
                    row.append(Hand(name: "\(ranks[i])\(ranks[j])s", type: .suited))
                } else {
                    row.append(Hand(name: "\(ranks[j])\(ranks[i])o", type: .offsuit))
                }
            }
            grid.append(row)
        }
        return grid
    }
    
    static func generateAllPossibleCombos(for hand: Hand, usedCards: Set<Card>) -> [[Card]] {
        let name = hand.name
        let isSuited = name.hasSuffix("s")
        let isPair = hand.type == .pair
        
        // カードのランクを取得
        let rankChars = Array(name.prefix(2))
        guard rankChars.count == 2,
              let firstRank = Rank(String(rankChars[0])),
              let secondRank = Rank(String(rankChars[1])) else {
            return []
        }
        
        let allSuits: [Suit] = [.spades, .hearts, .diamonds, .clubs]
        var possibleCombos: [[Card]] = []
        
        if isSuited {
            // スーテッドの場合
            for suit in allSuits {
                let card1 = Card(rank: firstRank, suit: suit)
                let card2 = Card(rank: secondRank, suit: suit)
                if !usedCards.contains(card1) && !usedCards.contains(card2) {
                    possibleCombos.append([card1, card2])
                }
            }
        } else if isPair {
            // ペアの場合
            for j in 0...3 {
                for i in 0...3 {
                    if i >= j { continue }

                    let card1 = Card(rank: firstRank, suit: allSuits[i])
                    let card2 = Card(rank: secondRank, suit: allSuits[j])
                    if !usedCards.contains(card1) && !usedCards.contains(card2) {
                        possibleCombos.append([card1, card2])
                    }
                }
            }
        } else {
            // オフスーテッド
            for suit1 in allSuits {
                for suit2 in allSuits {
                    if suit1 == suit2 { continue }
                    
                    let card1 = Card(rank: firstRank, suit: suit1)
                    let card2 = Card(rank: secondRank, suit: suit2)
                    if !usedCards.contains(card1) && !usedCards.contains(card2) {
                        possibleCombos.append([card1, card2])
                    }
                }
            }
        }
        
        return possibleCombos
    }
} 
