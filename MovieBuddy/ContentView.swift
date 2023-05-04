//
//  ContentView.swift
//  MovieBuddy
//
<<<<<<< HEAD
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


=======
//  Created by Nic Krystynak on 4/19/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
>>>>>>> origin/main
