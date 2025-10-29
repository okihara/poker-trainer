//
//  ComboView.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/01/29.
//

import SwiftUI

struct ComboView: View {
    @StateObject private var game = PokerGame()
    @State private var selectedCombos: [CardCombo] = []
    @State private var pendingCards: [Card] = []
    @State private var mode: Mode = .losing
    @State private var isInitialized: Bool = false
    @State private var resultMessage: String = ""
    @State private var hasAnswered: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showResultAnimation: Bool = false
    @State private var missedCombos: Set<CardCombo> = []
    @State private var correctCombos: Set<CardCombo> = []
    @State private var selectedPosition: PokerLogic.Position = .utgVsBtn
    @State private var selectedBoardSize: PokerLogic.BoardSize = .random

    private let handGrid = PokerLogic.generateHandGrid()

    enum Mode: String, CaseIterable {
        case winning = "勝っているハンド"
        case losing = "負けているハンド"

        var title: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerPickers
            boardSection
            modePicker

            if !resultMessage.isEmpty {
                resultSection
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    selectionControlSection
                    selectedComboSection
                    cardPickerSection
                }
                .padding(.horizontal)
            }

            actionButtons
        }
        .onAppear {
            if !isInitialized {
                isInitialized = true
                startNewProblem(position: selectedPosition, boardSize: selectedBoardSize)
            }
        }
        .onChange(of: selectedPosition) { newValue in
            startNewProblem(position: newValue, boardSize: selectedBoardSize)
        }
        .onChange(of: selectedBoardSize) { newValue in
            startNewProblem(position: selectedPosition, boardSize: newValue)
        }
    }

    private var headerPickers: some View {
        HStack {
            Picker("Position", selection: $selectedPosition) {
                ForEach(PokerLogic.Position.allCases, id: \.self) { position in
                    Text(position.rawValue).tag(position)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            Picker("Board Size", selection: $selectedBoardSize) {
                ForEach(PokerLogic.BoardSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    private var boardSection: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(game.board, id: \.self) { card in
                    Image(card.imageName)
                        .resizable()
                        .frame(width: 42, height: 66)
                        .shadow(radius: 4)
                }
            }

            HStack {
                ForEach(game.hand, id: \.self) { card in
                    Image(card.imageName)
                        .resizable()
                        .frame(width: 42, height: 66)
                        .shadow(radius: 4)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(Mode.allCases, id: \.self) { value in
                Text(value.title).tag(value)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var resultSection: some View {
        HStack(spacing: 8) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(isCorrect ? .green : .red)
                .scaleEffect(showResultAnimation ? 1.0 : 0.1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: showResultAnimation)
            Text(resultMessage)
                .font(.headline)
                .foregroundColor(isCorrect ? .green : .red)
                .padding(.bottom, 8)
                .opacity(showResultAnimation ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.2).delay(0.3), value: showResultAnimation)
        }
        .padding(.vertical, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Spacer()

            if !hasAnswered {
                Button(action: {
                    checkAnswer()
                }) {
                    Text("回答")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(selectedCombos.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedCombos.isEmpty)
            } else {
                Button(action: {
                    nextProblem()
                }) {
                    Text("次へ")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private var selectionControlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カードを2枚選択してコンボを追加")
                .font(.headline)

            HStack(spacing: 12) {
                HStack {
                    if pendingCards.isEmpty {
                        Text("未選択")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(pendingCards, id: \.self) { card in
                            Text(card.str)
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                Button("クリア") {
                    pendingCards.removeAll()
                }
                .disabled(pendingCards.isEmpty || hasAnswered)

                Button("追加") {
                    addPendingCombo()
                }
                .disabled(pendingCards.count < 2 || hasAnswered)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var selectedComboSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("選択したコンボ")
                .font(.headline)

            if selectedCombos.isEmpty {
                Text("まだコンボが追加されていません")
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(selectedCombos) { combo in
                        let isCorrectCombo = correctCombos.contains(combo)
                        let backgroundColor: Color
                        if hasAnswered {
                            backgroundColor = isCorrectCombo ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
                        } else {
                            backgroundColor = Color.gray.opacity(0.15)
                        }

                        HStack {
                            Text("\(combo.displayText) (\(combo.handName))")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            if hasAnswered {
                                Image(systemName: isCorrectCombo ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrectCombo ? .green : .red)
                            } else {
                                Button(action: {
                                    removeCombo(combo)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(8)
                        .background(backgroundColor)
                        .cornerRadius(8)
                    }
                }
            }

            if hasAnswered && !missedCombos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("未選択の正解コンボ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(sortedCombos(Array(missedCombos)), id: \.id) { combo in
                        Text("\(combo.displayText) (\(combo.handName))")
                            .padding(.vertical, 2)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var cardPickerSection: some View {
        let unavailableCards = Set(game.board + game.hand)
        let ranks: [Rank] = [.ace, .king, .queen, .jack, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two]
        let suits: [Suit] = [.spades, .hearts, .diamonds, .clubs]

        return VStack(alignment: .leading, spacing: 8) {
            Text("カード一覧")
                .font(.headline)

            ForEach(suits, id: \.self) { suit in
                HStack(spacing: 4) {
                    ForEach(ranks, id: \.self) { rank in
                        let card = Card(rank: rank, suit: suit)
                        CardSelectionButton(
                            card: card,
                            isSelected: pendingCards.contains(card),
                            isDisabled: hasAnswered || unavailableCards.contains(card),
                            isInAnyCombo: selectedCombos.contains(where: { $0.cards.contains(card) }),
                            action: {
                                handleCardTap(card)
                            }
                        )
                    }
                }
            }
        }
    }

    private func checkAnswer() {
        let myBestHandRank = game.evaluator.evaluateHand(cards: game.hand + game.board)
        let allHands = handGrid.flatMap { $0 }
        let usedCards = Set(game.board + game.hand)

        var rangeCombos: [CardCombo] = []

        for hand in allHands {
            let possibleCombos = PokerLogic.generateAllPossibleCombos(for: hand, usedCards: usedCards)
            let combosInRange = possibleCombos.filter { combo in
                game.isHandInRange(combo)
            }
            rangeCombos.append(contentsOf: combosInRange.map { CardCombo(cards: $0) })
        }

        let correctComboList = rangeCombos.filter { combo in
            let rank = game.evaluator.evaluateHand(cards: combo.cards + game.board)
            return mode == .losing ? rank > myBestHandRank : rank < myBestHandRank
        }

        let correctComboSet = Set(correctComboList)
        let selectedComboSet = Set(selectedCombos)

        correctCombos = correctComboSet
        missedCombos = correctComboSet.subtracting(selectedComboSet)
        isCorrect = selectedComboSet == correctComboSet

        let correctHandNames = Set(correctComboList.map { $0.handName })
        let selectedHandNames = Set(selectedCombos.map { $0.handName })

        let totalComboCount = rangeCombos.count
        let correctComboCount = correctComboList.count
        let ratio = totalComboCount == 0 ? 0.0 : Double(correctComboCount) / Double(totalComboCount)

        resultMessage = "正解: \(correctHandNames.count)ハンド(\(selectedHandNames.count))\n" +
        "割合: \(String(format: "%.1f", ratio * 100))% (\(correctComboCount)/\(totalComboCount)コンボ)"

        hasAnswered = true

        withAnimation {
            showResultAnimation = true
        }
    }

    private func nextProblem() {
        startNewProblem(position: selectedPosition, boardSize: selectedBoardSize)
    }

    private func startNewProblem(position: PokerLogic.Position, boardSize: PokerLogic.BoardSize) {
        game.startRandomBoard(position: position, boardSize: boardSize)
        resetSelections()
    }

    private func resetSelections() {
        selectedCombos = []
        pendingCards = []
        hasAnswered = false
        resultMessage = ""
        isCorrect = false
        showResultAnimation = false
        missedCombos = []
        correctCombos = []
    }

    private func addPendingCombo() {
        guard pendingCards.count == 2 else { return }
        let combo = CardCombo(cards: pendingCards)
        if !selectedCombos.contains(combo) {
            selectedCombos.append(combo)
        }
        pendingCards.removeAll()
    }

    private func removeCombo(_ combo: CardCombo) {
        if let index = selectedCombos.firstIndex(of: combo) {
            selectedCombos.remove(at: index)
        }
    }

    private func handleCardTap(_ card: Card) {
        guard !hasAnswered else { return }

        if let index = pendingCards.firstIndex(of: card) {
            pendingCards.remove(at: index)
        } else if pendingCards.count < 2 {
            pendingCards.append(card)
        }
    }

    private func sortedCombos(_ combos: [CardCombo]) -> [CardCombo] {
        combos.sorted { lhs, rhs in
            if lhs.handName == rhs.handName {
                return lhs.displayText < rhs.displayText
            }
            return lhs.handName < rhs.handName
        }
    }
}

struct CardCombo: Identifiable, Hashable {
    private let internalCards: [Card]

    init(cards: [Card]) {
        self.internalCards = cards.sorted { lhs, rhs in
            if lhs.rank == rhs.rank {
                return lhs.suit.rawValue < rhs.suit.rawValue
            }
            return lhs.rank.rawValue > rhs.rank.rawValue
        }
    }

    var cards: [Card] { internalCards }

    var id: String {
        internalCards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: "-")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CardCombo, rhs: CardCombo) -> Bool {
        lhs.id == rhs.id
    }

    var displayText: String {
        internalCards.map { $0.str }.joined(separator: " ")
    }

    var handName: String {
        HandRange.handToString(internalCards)
    }
}

struct CardSelectionButton: View {
    let card: Card
    let isSelected: Bool
    let isDisabled: Bool
    let isInAnyCombo: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.2)
        }
        if isSelected {
            return Color.blue
        }
        if isInAnyCombo {
            return Color.green.opacity(0.4)
        }
        return Color.gray.opacity(0.5)
    }

    var body: some View {
        Button(action: action) {
            Text(card.str)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
