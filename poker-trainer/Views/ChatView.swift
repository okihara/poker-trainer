import SwiftUI

// チャットメッセージのモデル
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// ViewModel（データ管理とロジック）
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [
        Message(text: "最初の問題！2+2は？", isUser: false)
    ]
    @Published var inputText: String = ""

    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // ユーザーのメッセージを追加
        let userMessage = Message(text: inputText, isUser: true)
        messages.append(userMessage)
        
        let answer = "4"  // 正解
        let responseText = (inputText == answer) ? "正解！次の問題へ" : "不正解！もう一度考えてみて"
        
        // 入力をクリア
        inputText = ""

        // ボットの返信を遅延して追加
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botMessage = Message(text: responseText, isUser: false)
            self.messages.append(botMessage)
        }
    }
}

// SwiftUIのメインビュー
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        VStack {
            // チャットの表示エリア
            List(viewModel.messages) { message in
                HStack {
                    if message.isUser {
                        Spacer()
                        Text(message.text)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text(message.text)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        Spacer()
                    }
                }
            }
            
            // 入力エリア
            HStack {
                TextField("メッセージを入力", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: viewModel.sendMessage) {
                    Text("送信")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// プレビュー
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
