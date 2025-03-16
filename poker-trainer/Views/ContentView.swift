import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ComboView()
                .tabItem {
                    Label("コンボ練習", systemImage: "gamecontroller")
                }

            OutsView()
                .tabItem {
                    Label("アウツ練習", systemImage: "gamecontroller")
                }
            
            TextureView()
                .tabItem {
                    Label("フロップ", systemImage: "percent")
                }
            
            ChatView()
                .tabItem {
                    Label("チャット風", systemImage: "gamecontroller")
                }
        }
    }
}

