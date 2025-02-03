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
    
    private func createDeck() -> [Card] {
        var deck: [Card] = []
        for suit in suits {
            for rank in ranks {
                deck.append(Card(rank: rank, suit: suit))
            }
        }
        return deck.shuffled()
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
