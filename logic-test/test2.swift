//
//  test2.swift
//  test2
//
//  Created by Masataka Okihara on 2025/01/28.
//

import XCTest

final class test2: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOuts() throws {
        let hand = [
            Card(rank: .ace, suit: .spades),
            Card(rank: .king, suit: .spades)
            ]
        let board = [
            Card(rank: .jack, suit: .hearts),
            Card(rank: .king, suit: .clubs),
            Card(rank: .eight, suit: .spades),
        ]
        XCTAssertEqual(PokerHandEvaluator().calculateOuts(hand: hand, board: board).count, 5)
    }

    func testFullHouse() throws {
        // フルハウスのテストケース
        let cards = [
            Card(rank: .three, suit: .hearts),
            Card(rank: .three, suit: .diamonds),
            Card(rank: .three, suit: .clubs),
            Card(rank: .king, suit: .spades),
            Card(rank: .king, suit: .hearts),
            Card(rank: .king, suit: .clubs)
        ]
        let result = PokerHandEvaluator().evaluateHand(cards: cards)
        XCTAssertEqual(result.rankType, .fullHouse)
        XCTAssertEqual(result.ranks[0], .king)
        XCTAssertEqual(result.ranks[1], .three)
    }
    
    func testFullHouse2() throws {
        let hand = [
            Card(rank: .six, suit: .hearts),
            Card(rank: .king, suit: .spades)
        ]
        let board = [
            Card(rank: .ten, suit: .spades),
            Card(rank: .eight, suit: .clubs),
            Card(rank: .six, suit: .clubs),
            Card(rank: .king, suit: .diamonds),
            Card(rank: .king, suit: .hearts)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        XCTAssertEqual(result.rankType, .fullHouse, "AhKs + 10s8c6cKdKh はフルハウスになるはずです")
        XCTAssertEqual(result.ranks[0], .king, "フルハウスのスリーカードはキングになるはずです")
        XCTAssertEqual(result.ranks[1], .six, "フルハウスのペアはエースになるはずです")
    }
        
    func testBoardOnePair() throws {
        let hand = [
            Card(rank: .ten, suit: .clubs),
            Card(rank: .queen, suit: .diamonds)
        ]
        let board = [
            Card(rank: .seven, suit: .spades),
            Card(rank: .five, suit: .clubs),
            Card(rank: .two, suit: .hearts),
            Card(rank: .seven, suit: .clubs),
            Card(rank: .king, suit: .diamonds)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        print(result)
        XCTAssertEqual(result.rankType, .onePair)
        XCTAssertEqual(result.ranks[0], .seven)
        XCTAssertEqual(result.ranks[1], .king)
        XCTAssertEqual(result.ranks[2], .queen)
    }

    func testStraight() throws {
        let hand = [
            Card(rank: .nine, suit: .hearts),
            Card(rank: .nine, suit: .spades)
        ]
        let board = [
            Card(rank: .ten, suit: .spades),
            Card(rank: .six, suit: .hearts),
            Card(rank: .three, suit: .clubs),
            Card(rank: .seven, suit: .diamonds),
            Card(rank: .eight, suit: .hearts)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        XCTAssertEqual(result.rankType, .straight)
        XCTAssertEqual(result.ranks[0], .ten)
    }

    func testTwoPair2() throws {
        let hand = [
            Card(rank: .ace, suit: .clubs),
            Card(rank: .three, suit: .clubs)
        ]
        let board = [
            Card(rank: .six, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .six, suit: .spades),
            Card(rank: .two, suit: .diamonds),
            Card(rank: .ace, suit: .spades)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        XCTAssertEqual(result.rankType, .twoPair, "エースペアと6のペアでツーペアになるはずです")
        XCTAssertEqual(result.ranks[0], .ace, "ツーペアの高い方はエースになるはずです")
        XCTAssertEqual(result.ranks[1], .six, "ツーペアの低い方は6になるはずです")
        XCTAssertEqual(result.ranks[2], .nine, "キッカーは9になるはずです")
    }

    // ６のペアで２が消されるパターン
    func testTwoPair3() throws {
        let hand = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .two, suit: .hearts)
        ]
        let board = [
            Card(rank: .six, suit: .hearts),
            Card(rank: .nine, suit: .clubs),
            Card(rank: .six, suit: .spades),
            Card(rank: .two, suit: .diamonds),
            Card(rank: .ace, suit: .spades)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        XCTAssertEqual(result.rankType, .twoPair, "エースペアと6のペアでツーペアになるはずです")
        XCTAssertEqual(result.ranks[0], .ace, "ツーペアの高い方はエースになるはずです")
        XCTAssertEqual(result.ranks[1], .six, "ツーペアの低い方は6になるはずです")
        XCTAssertEqual(result.ranks[2], .nine, "キッカーは9になるはずです")
    }

    func testFlush() throws {
        let hand = [
            Card(rank: .ace, suit: .hearts),
            Card(rank: .two, suit: .hearts)
        ]
        let board = [
            Card(rank: .queen, suit: .hearts),
            Card(rank: .five, suit: .hearts),
            Card(rank: .jack, suit: .hearts),
            Card(rank: .jack, suit: .spades),
            Card(rank: .king, suit: .spades)
        ]
        
        let result = PokerHandEvaluator().evaluateHand(cards: hand + board)
        XCTAssertEqual(result.rankType, .flush, "ハートのA,2,Q,5,Jでフラッシュになるはずです")
        XCTAssertEqual(result.ranks[0], .ace, "フラッシュの最高位カードはエースになるはずです")
        XCTAssertEqual(result.ranks[1], .queen, "フラッシュの2番目に高いカードはクイーンになるはずです")
        XCTAssertEqual(result.ranks[2], .jack, "フラッシュの3番目に高いカードはジャックになるはずです")
        XCTAssertEqual(result.ranks[3], .five, "フラッシュの4番目に高いカードは5になるはずです")
        XCTAssertEqual(result.ranks[4], .two, "フラッシュの5番目に高いカードは2になるはずです")
    }
}
