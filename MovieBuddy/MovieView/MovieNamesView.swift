//
//  MovieNamesView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/27/23.
//

import SwiftUI

struct MovieNamesView: View {
    @State private var movieNames: [String]
    @Binding var isLoading: Bool
    @State private var movieId: Int?
    var apiManager = APIManager()
    
    //Properties for showing the movie detail sheet
    @State private var showingMovieDetails = false

    

    init(movieNames: [String], isLoading: Binding<Bool>) {
        _movieNames = State(initialValue: movieNames)
        _isLoading = isLoading
    }
    
    @State private var statusMessage: String = ""


    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(movieNames, id: \.self) { movieName in
                            Button(action: {
                                isLoading = true
                                apiManager.searchMovieByName(movieName) { result in
                                    switch result {
                                    case .success(let movieId):
                                        DispatchQueue.main.async {
                                            self.isLoading = false
                                            self.movieId = movieId
                                            self.showingMovieDetails = true
                                        }
                                    case .failure(let error):
                                        DispatchQueue.main.async {
                                            self.isLoading = false
                                            self.statusMessage = "Error: \(error.localizedDescription)"
                                        }
                                    }
                                }
                            }) {
                                Text(movieName)
                            }

                        }
                    }
                    .sheet(isPresented: $showingMovieDetails) {
                        MovieDetailsView(movieId: movieId ?? 0)
                    }

                }
            }
        }

    }

}

