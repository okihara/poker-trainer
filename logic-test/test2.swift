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
}
