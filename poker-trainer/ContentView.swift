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
    
    // プリフロップレンジを定義
    private func isHandInRange(_ card1: Card, _ card2: Card) -> Bool {
        let ranks = [card1.rank, card2.rank].sorted { $0.rawValue > $1.rawValue }
        let suited = card1.suit == card2.suit
        
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
            if isHandInRange(deck[i], deck[i + 1]) {
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

struct ContentView: View {
    var body: some View {
        TabView {
            ComboView()
                .tabItem {
                    Label("コンボ練習", systemImage: "gamecontroller")
                }


            GameView()
                .tabItem {
                    Label("アウツ練習", systemImage: "gamecontroller")
                }
            
            ChatView()
                .tabItem {
                    Label("チャット風", systemImage: "gamecontroller")
                }
        }
    }
}

struct GameView: View {
    @StateObject private var game = PokerGame()
    
    var body: some View {
        VStack {
            if game.isLoading {
                // ローディング画面
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2.0)
                    
                    Text(game.feedback)
                        .font(.title)
                        .padding(.top, 20)
                }
                .transition(.opacity) // フェードイン/アウト
            } else {
                Text("コミュニティカード")
                    .font(.title)
                    .padding(.top, 20)
                
                HStack {
                    ForEach(game.board, id: \.self) { card in
                        Image(card.imageName)
                            .resizable()
                            .frame(width: 60, height: 90)
                            .shadow(radius: 4)
                    }
                }
                
                Text("手札")
                    .font(.title)
                    .padding(.top, 5)
                HStack {
                    ForEach(game.hand, id: \.self) { card in
                        Image(card.imageName)
                            .resizable()
                            .frame(width: 60, height: 90)
                            .shadow(radius: 4)
                    }
                }
                
                Text("アウツを選んでください")
                    .font(.headline)
                    .padding(.top, 10)
                
                VStack {
                    ForEach(game.options, id: \.self) { opt in
                        Button(action: {
                            game.checkAnswer(opt)
                        }) {
                            Text("\(opt)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .bold()
                                .cornerRadius(8)
                        }
                    }

                }
                
                Text(game.feedback)
                    .font(.headline)
                    .padding(.top, 10)

            }
        }
        .onAppear {
            game.startGame()
        }
        .padding()
    }
}
