//
//  MovieDetailsView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/23/23.
//

import SwiftUI
import Combine
import WebKit

struct MovieDetailsView: View {
    var movieId: Int
    
    @State private var movieName: String = ""
    
    @State private var statusMessage: String = ""
    @State private var posterImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var movieVideos: [MovieVideo] = []
    
    
    //Vars for wath providers
    @State private var movieDetails: APIManager.MovieDetails?
    @State private var movieWatchProviders: [WatchProvider] = []
    
    //button for the description view
    @State private var isDescriptionExpanded: Bool = false
    @State private var isMoreInfoSheetPresented: Bool = false


    struct MovieVideo: Identifiable, Hashable {
        let id: String
        let name: String
        let site: String
        let key: String
    }
    
    private let apiManager = APIManager()
    
    //vars for adding likes and wish list
    @State private var isMovieInWishlist: Bool = false
    @State private var isMovieLiked: Bool = false


    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Set the movie poster as the background of the entire view
                    if let posterImage = posterImage {
                        Image(uiImage: posterImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                    }
                    
                

                    // Wrap the content in a semi-transparent card
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoading {
                                ActivityIndicator(isAnimating: $isLoading, style: .large)
                            } else if !statusMessage.isEmpty {
                                Text(statusMessage)
                            } else if let movieDetails = movieDetails {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack {
                                        HStack {
                                            Text("\(movieDetails.title)")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(String(format: "%.1f", movieDetails.voteAverage))/10")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                        }

                                        if let firstYouTubeVideo = movieVideos.first(where: { $0.site == "YouTube" }) {
                                            YouTubeVideoView(videoID: firstYouTubeVideo.key)
                                                .frame(height: 200)
                                        } else {
                                            Text("No trailers found")
                                        }
                                    }
                                    .padding(5)

                                    VStack(alignment: .leading, spacing: 16) {
                    
                                        
                                        Text("\(movieDetails.overview)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                        
                                        
                                        //section for new buttons
                                        HStack {
                                            Button(action: {
                                                toggleWishlistStatus()
                                            }) {
                                                HStack {
                                                    Image(systemName: isMovieInWishlist ? "heart.fill" : "heart")
                                                    Text(isMovieInWishlist ? "Remove from Wishlist" : "Add to Wishlist")
                                                }
                                                .foregroundColor(isMovieInWishlist ? .red : .white)
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Button(action: {
                                                toggleLikedStatus()
                                            }) {
                                                HStack {
                                                    Image(systemName: isMovieLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                                    Text(isMovieLiked ? "Unlike" : "Like")
                                                }
                                                .foregroundColor(isMovieLiked ? .green : .white)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }

                                            

                                        Button(action: {
                                            isMoreInfoSheetPresented = true
                                        }) {
                                            Text("More")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.blue)
                                                
                                        }
                                    }
                                    .padding(.horizontal)
                                    .sheet(isPresented: $isMoreInfoSheetPresented) {
                                        // The view that gets displayed when the user clicks on more info
                                        MoreInfoView(movieDetails: movieDetails, posterImage: posterImage)
                                    }
                                }
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(16)
                                
                            }

                            // Watch providers section
                            WatchProvidersView(watchProviders: movieWatchProviders, apiManager: apiManager)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(16)
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                self.isLoading = true
                self.fetchDetailsAndPoster(for: movieId)
                self.fetchMovieVideos(for: movieId)
                self.fetchMovieWatchProviders(for: movieId)
                
                print(movieId, "This is the movide ID!")
            }
            .tabItem {
                Label("Movies", systemImage: "film")
            }
        }
    }
    
    private func toggleWishlistStatus() {
        // Update the database and the isMovieInWishlist state
    }

    private func toggleLikedStatus() {
        // Update the database and the isMovieLiked state
    }

    
    private func fetchDetailsAndPoster(for movieId: Int) {
        apiManager.fetchMovieDetails(by: movieId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let details):
                    self.movieDetails = details
                    if let posterPath = details.posterPath {
                        self.fetchPosterImage(posterPath: posterPath)
                    }
                case .failure(let error):
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func fetchPosterImage(posterPath: String) {
        apiManager.fetchImage(at: posterPath) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self.posterImage = image
                case .failure(let error):
                    self.statusMessage = "Error: \(error.localizedDescription)"
               
                }
            }
        }
    }

    private func fetchMovieVideos(for movieId: Int) {
        apiManager.getMovieVideos(movieID: movieId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videos):
                    self.movieVideos = videos.compactMap { video in
                        if let name = video["name"] as? String,
                           let site = video["site"] as? String,
                           let key = video["key"] as? String,
                           let id = video["id"] as? String {
                            return MovieVideo(id: id, name: name, site: site, key: key)
                        } else {
                            return nil
                        }
                    }
                case .failure(let error):
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func fetchMovieWatchProviders(for movieId: Int) {
        apiManager.getMovieWatchProviders(movieID: movieId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let watchProvidersData):
                    print("Watch providers data: \(watchProvidersData)")
                    if let countryCode = Locale.current.regionCode,
                       let countryData = watchProvidersData[countryCode] as? [String: Any],
                       let buyProvidersData = countryData["buy"] as? [[String: Any]] {
                        
                        self.movieWatchProviders = buyProvidersData.compactMap { WatchProvider(json: $0) }
                        
                    } else {
                        self.statusMessage = "No watch providers found for the current country."
                    }
                case .failure(let error):
                    print("Error in fetchMovieWatchProviders: \(error.localizedDescription)")
                    self.statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

