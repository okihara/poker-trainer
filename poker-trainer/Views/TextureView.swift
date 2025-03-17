//
//  TextureView.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/03/17.
//

import SwiftUI

struct TextureView: View {
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
                Text("正しいテクスチャ情報を選べ")
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
                .padding(.vertical, 20)

                
                HStack {
                    Text("ポット: \(Int(game.potSize))")
                    Spacer()
                    Text("ベット: \(Int(game.betSize))")
                }
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)

                
                if !game.feedback.isEmpty {
                    Text(game.feedback)
                        .font(.headline)
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                    
                    // 不正解の場合、次の問題へボタンを表示
                    if game.showNextButton {
                        Button(action: {
                            game.nextTextureQuestion()
                        }) {
                            Text("次の問題へ")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                
                // テクスチャー判断UI
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // スートの割合
                        VStack(alignment: .leading) {
                            Text("スートの割合")
                                .font(.headline)
                            
                            HStack {
                                ForEach(PokerGame.SuitTexture.allCases) { texture in
                                    Button(action: {
                                        game.selectedSuitTexture = texture
                                        checkAllSelected()
                                    }) {
                                        Text(texture.rawValue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.selectedSuitTexture == texture ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(game.selectedSuitTexture == texture ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // コネクト具合
                        VStack(alignment: .leading) {
                            Text("コネクト具合")
                                .font(.headline)
                            
                            HStack {
                                ForEach(PokerGame.ConnectTexture.allCases) { texture in
                                    Button(action: {
                                        game.selectedConnectTexture = texture
                                        checkAllSelected()
                                    }) {
                                        Text(texture.rawValue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.selectedConnectTexture == texture ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(game.selectedConnectTexture == texture ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // ペア具合
                        VStack(alignment: .leading) {
                            Text("ペア具合")
                                .font(.headline)
                            
                            HStack {
                                ForEach(PokerGame.PairTexture.allCases) { texture in
                                    Button(action: {
                                        game.selectedPairTexture = texture
                                        checkAllSelected()
                                    }) {
                                        Text(texture.rawValue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.selectedPairTexture == texture ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(game.selectedPairTexture == texture ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // ハイボード具合
                        VStack(alignment: .leading) {
                            Text("ハイボード具合")
                                .font(.headline)
                            
                            HStack {
                                ForEach(PokerGame.HighCardTexture.allCases) { texture in
                                    Button(action: {
                                        game.selectedHighCardTexture = texture
                                        checkAllSelected()
                                    }) {
                                        Text(texture.rawValue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.selectedHighCardTexture == texture ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(game.selectedHighCardTexture == texture ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // 必要勝率
                        VStack(alignment: .leading) {
                            Text("必要勝率")
                                .font(.headline)
                            
                            HStack {
                                ForEach(game.equityOptions, id: \.self) { equity in
                                    Button(action: {
                                        game.selectedEquity = equity
                                        checkAllSelected()
                                    }) {
                                        Text("\(Int(equity * 100))%")
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(game.selectedEquity == equity ? Color.blue : Color.gray.opacity(0.3))
                                            .foregroundColor(game.selectedEquity == equity ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            game.startTextureGame()
        }
        .padding()
    }
    
    // すべての項目が選択されたかチェックし、選択されていれば回答処理を実行
    private func checkAllSelected() {
        if game.selectedSuitTexture != nil &&
           game.selectedConnectTexture != nil &&
           game.selectedPairTexture != nil &&
           game.selectedHighCardTexture != nil &&
           game.selectedEquity != nil {
            var res = game.checkTextureAnswer()
            // 必要勝率のチェックは別途行われるため、ここでは何もしない
        }
    }
}

#Preview {
    TextureView()
}
