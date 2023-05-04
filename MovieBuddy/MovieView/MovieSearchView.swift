//
//  MovieSearchView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/23/23.
//

import SwiftUI

struct MovieSearchView: View {
    @State private var movieName: String = ""
    @State private var movieId: Int?
    
    @State private var statusMessage: String = ""
    @State private var posterImage: UIImage?
    @State private var isLoading: Bool = false
    
   

    
    private let apiManager = APIManager()

    var body: some View {
        NavigationView {
            VStack {
                Section(header: Text("Movie Search")) {
                    TextField("Put movie name here", text: $movieName)
                    Button(action: {
                        self.isLoading = true
                        self.statusMessage = ""

                        apiManager.searchMovieByName(movieName) { result in
                            switch result {
                            case .success(let movieId):
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.movieId = movieId
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.statusMessage = "Error: \(error.localizedDescription)"
                                }
                            }
                        }
                    }) {
                        Text("Search")
                    }
                }

                if isLoading {
                    ActivityIndicator(isAnimating: $isLoading, style: .large)
                } else if !statusMessage.isEmpty {
                    Text(statusMessage)
                }

                NavigationLink(destination: MovieDetailsView(movieId: movieId ?? 0), isActive: Binding(get: {
                    
                    movieId != nil
                    
                }, set: { _ in
                    movieId = nil
                    
                })) {
                    EmptyView()
                }
            }
        }.tabItem {
            Label("Movies", systemImage: "film")
        }
    }
}

struct MovieSearchView_Previews: PreviewProvider {
    static var previews: some View {
        MovieSearchView()
    }
}

