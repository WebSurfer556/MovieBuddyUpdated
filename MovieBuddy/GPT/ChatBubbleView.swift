//
//  ChatBubbleView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/25/23.
//
import SwiftUI


struct ChatBubbleView: View {
    let message: APIManager.Message
    let movieNames: [String]

    @Binding var isLoading: Bool
    
    //checks if the api for movie names is done
    @Binding var isExtractingMovieNames: Bool
    
    
    // Check if the current message is the most recent assistant message
    let isMostRecentAssistantMessage: Bool


    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: .leading) {
                Text("\(message.role):")
                    .font(.headline)
                Text(message.content)
                    .padding()
                    .background(message.role == "user" ? Color.blue : Color(.systemGray6))
                    .foregroundColor(message.role == "user" ? .white : .black)
                    .cornerRadius(10)
                
                if message.role == "assistant" && !movieNames.isEmpty && !isExtractingMovieNames && isMostRecentAssistantMessage {
                            Spacer().frame(height: 8)
                            MovieNamesView(movieNames: movieNames, isLoading: $isLoading)
                        }
            }
            .padding(.bottom)
            
            if message.role == "assistant" {
                Spacer()
            }
        }
    }
}
