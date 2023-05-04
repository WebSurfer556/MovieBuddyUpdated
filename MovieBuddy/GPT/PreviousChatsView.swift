//
//  PreviousChatsView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/27/23.
//

import SwiftUI

struct PreviousChatsView: View {
    let initialQuestion: String
    let previousChats: [APIManager.Message]
    @Binding var isLoading: Bool
    let movieNames: [String]
    
    //computed property to store the current chat index
    private var mostRecentAssistantMessageIndex: Int? {
        return previousChats.enumerated().compactMap { index, message in
            message.role == "assistant" ? index : nil
        }.last
    }
    
    //checks if the api for movie names is done
    @Binding var isExtractingMovieNames: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Previous chats:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading) {
                Text("Assistant:")
                    .font(.headline)
                Text(initialQuestion)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            
            //pass current index to Bubble view to display
            ForEach(previousChats.indices, id: \.self) { index in
                ChatBubbleView(message: previousChats[index], movieNames: movieNames, isLoading: $isLoading, isExtractingMovieNames: $isExtractingMovieNames, isMostRecentAssistantMessage: index == mostRecentAssistantMessageIndex)
                    .id(index) // Assign a unique ID to each chat bubble
            }

            
            if isLoading {
                HStack {
                    Spacer()
                    ActivityIndicator(isAnimating: $isLoading, style: .medium)
                    Spacer()
                }
            }
        }
    }
}

