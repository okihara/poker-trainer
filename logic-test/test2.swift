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

    func testExample() throws {
        // フルハウスのテストケース
        let fullHouseCards = [
            Card(rank: .three, suit: .hearts),
            Card(rank: .three, suit: .diamonds),
            Card(rank: .three, suit: .clubs),
            Card(rank: .king, suit: .spades),
            Card(rank: .king, suit: .hearts),
            Card(rank: .ace, suit: .hearts)
        ]
        assert(PokerHandEvaluator().evaluateHand(cards: fullHouseCards).rankType == .fullHouse, "フルハウスのテストに失敗しました")
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
}
