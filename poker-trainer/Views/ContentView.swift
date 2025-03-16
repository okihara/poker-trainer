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
            
            PotOddsTrainerView()
                .tabItem {
                    Label("ポットオッズ", systemImage: "percent")
                }
            
            ChatView()
                .tabItem {
                    Label("チャット風", systemImage: "gamecontroller")
                }
        }
    }
}

