//
//  ChatInputView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/27/23.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var userInput: String
    let onSend: () -> Void
    let isLoading: Bool

    var body: some View {
        HStack {
            TextField("Enter your text here", text: $userInput)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: 100)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isLoading)
        }
    }
}

