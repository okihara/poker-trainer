import Foundation

struct PreflopRanking {
    static let allHands: [Hand] = PokerLogic.generateHandGrid().flatMap { $0 }

    private static func score(for cards: [Card]) -> Int {
        let ranks = cards.map { $0.rank.rawValue }.sorted(by: >)
        let high = ranks[0]
        let low = ranks[1]
        var score = high * 20 + low
        if cards[0].suit == cards[1].suit { score += 2 }
        if high == low { score += 200 }
        return score
    }

    static let ranking: [Hand] = allHands.sorted { score(for: $0.dummyCards) > score(for: $1.dummyCards) }

    static func rankIndex(of cards: [Card]) -> Int? {
        let handStr = HandRange.handToString(cards)
        return ranking.firstIndex(where: { $0.name == handStr })
    }
}
