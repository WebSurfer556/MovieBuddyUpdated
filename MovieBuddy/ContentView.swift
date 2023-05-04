//
//  ContentView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/20/23.
//

import SwiftUI
import Alamofire

struct ContentView: View {
    let sessionManager = SessionManager()
    let username = "some_username"
    
    init() {
        sessionManager.createUser(username: username)
    }
    
    var body: some View {
        TabView {
            ChatView(username: username)
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            MovieSearchView()
            
            UserPreferencesView(username: username)
        }
    }
}


