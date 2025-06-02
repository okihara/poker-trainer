import SwiftUI

struct CallDecisionTrainerView: View {
    @State private var potSize: Double = 40
    @State private var betSize: Double = 20
    @State private var hand: [Card] = []
    @State private var showResult: Bool = false
    @State private var resultMessage: String = ""

    private var defenseRatio: Double {
        potSize / (potSize + betSize)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("ポット: \(Int(potSize))BB")
                .foregroundColor(.white)
            Text("ベット: \(Int(betSize))BB")
                .foregroundColor(.white)
            Text("ディフェンス割合: \(Int(defenseRatio * 100))%")
                .foregroundColor(.white)
            HStack {
                ForEach(hand, id: \.self) { card in
                    Image(card.imageName)
                        .resizable()
                        .frame(width: 60, height: 90)
                        .shadow(radius: 4)
                }
            }
            if let index = PreflopRanking.rankIndex(of: hand) {
                Text("ハンドランク: \(index + 1)/\(PreflopRanking.ranking.count)")
                    .foregroundColor(.white)
            }
            HStack(spacing: 40) {
                Button("コール") { evaluate(call: true) }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                Button("フォールド") { evaluate(call: false) }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            if showResult {
                Text(resultMessage)
                    .font(.title)
                    .foregroundColor(.yellow)
            }
            Button("次の問題") { newQuestion() }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.black)
        .onAppear { newQuestion() }
    }

    private func evaluate(call: Bool) {
        guard let index = PreflopRanking.rankIndex(of: hand) else { return }
        let callCount = Int(Double(PreflopRanking.ranking.count) * defenseRatio)
        let shouldCall = index < callCount
        showResult = true
        resultMessage = (call == shouldCall) ? "正解！" : "不正解"
    }

    private func newQuestion() {
        let deck = PokerGame().createDeck()
        hand = Array(deck.prefix(2))
        potSize = Double(Int.random(in: 20...80))
        betSize = Double(Int.random(in: 10...40))
        showResult = false
        resultMessage = ""
    }
}

#Preview {
    CallDecisionTrainerView()
}
