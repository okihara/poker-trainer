//
//  OutsView.swift
//  poker-trainer
//
//  Created by Masataka Okihara on 2025/03/17.
//

import SwiftUI

struct OutsView: View {
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
