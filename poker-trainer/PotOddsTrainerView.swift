import SwiftUI

enum Position: String, CaseIterable {
    case utg = "UTG"
    case hj = "HJ"
    case co = "CO"
    case btn = "BTN"
    case sb = "SB"
    case bb = "BB"
}

struct PositionIndicator: View {
    let position: Position
    let isActive: Bool
    let angle: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
            
            Text(position.rawValue)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
                .rotationEffect(.degrees(-90)) // テーブル全体の回転を打ち消す
        }
        .rotationEffect(.degrees(angle))
    }
}

struct PotOddsTrainerView: View {
    @State private var potSize: Double = 100
    @State private var betSize: Double = 50
    @State private var userAnswer: String = ""
    @State private var showResult: Bool = false
    @State private var bettingPosition: Position = .co
    
    private var correctPotOdds: Double {
        let totalPot = potSize + betSize
        return (betSize / totalPot) * 100
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // ポーカーテーブルの表示
                ZStack {
                    // テーブルの外枠
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 300, height: 300)
                    
                    // ポットサイズの表示
                    VStack {
                        Text("ポット")
                            .foregroundColor(.white)
                        Text("\(Int(potSize))BB")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    // ポジションの表示
                    ForEach(Array(Position.allCases.enumerated()), id: \.element) { index, position in
                        let angle = Double(index) * (360.0 / Double(Position.allCases.count))
                        PositionIndicator(position: position,
                                       isActive: position == bettingPosition,
                                       angle: angle)
                            .offset(y: -120)
                            .rotationEffect(.degrees(-angle + 180)) // 180度回転させてUTGを上部に配置
                    }
                    
                    // アクティブなプレイヤーのベット表示
                    if let activeIndex = Position.allCases.firstIndex(of: bettingPosition) {
                        let angle = Double(activeIndex) * (360.0 / Double(Position.allCases.count))
                        Text("Bet: \(Int(betSize))BB")
                            .padding(8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .offset(y: -80)
                            .rotationEffect(.degrees(angle + 180)) // ベット表示も同様に調整
                    }
                }
                .rotationEffect(.degrees(90)) // テーブル全体を回転して位置を調整
                
                // 計算入力エリア
                VStack(spacing: 10) {
                    Text("ポットオッズを計算してください")
                        .foregroundColor(.white)
                    
                    TextField("答えを入力 (%)", text: $userAnswer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 200)
                    
                    Button("確認") {
                        showResult = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    if showResult {
                        let userVal = Double(userAnswer) ?? 0
                        let isCorrect = abs(userVal - correctPotOdds) < 0.1
                        
                        Text(isCorrect ? "正解！" : "不正解")
                            .foregroundColor(isCorrect ? .green : .red)
                        Text("正しい答え: \(String(format: "%.1f", correctPotOdds))%")
                            .foregroundColor(.white)
                    }
                }
                
                // 新しい問題生成ボタン
                Button("新しい問題") {
                    potSize = Double.random(in: 50...200)
                    betSize = Double.random(in: 20...100)
                    bettingPosition = Position.allCases.randomElement() ?? .co
                    userAnswer = ""
                    showResult = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    PotOddsTrainerView()
}
