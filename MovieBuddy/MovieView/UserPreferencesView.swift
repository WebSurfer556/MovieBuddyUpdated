//
//  UserPreferencesView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/28/23.
//

import SwiftUI

struct UserPreferencesView: View {
    // Add your data models or observed objects here
    var apiManager = APIManager()
    
    var dbManager = DatabaseManager()
    
    //This is the username for the session
    let username: String
    
    //used for the userID fetching preferences
    @State private var userID: Int64?
    
    //section for actually holding the nessecary stuff
    @State private var likedMovies: [Movie] = []
    @State private var wishlistMovies: [Movie] = []
   
    
    //search bar
    @State private var searchQuery: String = ""
    
    //an array for holding the search results
    @State private var searchResults: [APIManager.Movie] = []
    @State private var searchResultPeople: [APIManager.Person] = []
    
    //For holding images 
    @State private var favoriteDirectors: [APIManager.PersonInfo] = []
    @State private var favoriteActors: [APIManager.PersonInfo] = []
    
    
    
    //for displaying the image
    @State private var image: UIImage? = nil
    
    
    //vars for presenting the sheets for movie detail view
    @State private var isMovieDetailsPresented: Bool = false
    @State private var selectedMovieId: Int?

    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            // Search bar
            SearchBar(text: $searchQuery)
                        .padding(.horizontal)
                        .onChange(of: searchQuery) { _ in
                            fetchSearchResults()
                        }
            
            List {
                Group {
                    ForEach(searchResults, id: \.id) { movie in
                        SearchResultRow(movie: movie, onAddButtonPressed: {
                            addMovie(itemID: movie.id, itemType: "movie", itemName: movie.title)
                        })
                    }
                    
                    
                    ForEach(searchResultPeople, id: \.id) { person in
                        SearchResultPersonRow(person: person, onAddButtonPressed: {
                            // Pass the imageURL when calling addButtonPressed
                            addPerson(itemID: person.id, itemType: "person", itemName: person.name, imageURL: person.profilePath, personID: person.id)
                        })
                    }
                }
                
                // Wishlist Section
                Section(header: Text("Wish List")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(wishlistMovies, id: \.id) { movie in
                                CustomItemViewWithTap(movie: movie, onAddButtonPressed: nil)
                            }
                        }
                    }
                }

                
                // Liked Movies Section
                Section(header: Text("Liked Movies")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(likedMovies, id: \.id) { movie in
                                CustomItemViewWithTap(movie: movie, onAddButtonPressed: nil)
                            }
                        }
                    }
                }

                
                
                /// Favorite Directors Section
                Section(header: Text("Favorite Directors")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(favoriteDirectors, id: \.id) { director in
                                CustomItemView(title: director.name, imageURL: director.imagePath, onAddButtonPressed: nil)
                                    .onTapGesture {
                                        // Navigate to director detail view
                                    }
                            }
                        }
                    }
                }
                
                // Favorite Actors Section
                Section(header: Text("Favorite Actors")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(favoriteActors, id: \.id) { actor in
                                CustomItemView(title: actor.name, imageURL: actor.imagePath, onAddButtonPressed: nil)
                                    .onTapGesture {
                                        // Navigate to actor detail view
                                    }
                            }
                        }
                    }
                }
            }
            }
            .listStyle(InsetGroupedListStyle())
            .padding()
        }
        
    func fetchSearchResults() {
        apiManager.find(id: searchQuery, externalSource: "imdb_id") { (result) in
            switch result {
            case .success(let findResponse):

                self.searchResultPeople = findResponse.results.compactMap { result -> APIManager.Person? in
                    if case .person(let person) = result {
                        return person
                    }
                    return nil
                }

                
                self.searchResults = findResponse.results.compactMap { result -> APIManager.Movie? in
                    if case .movie(let movie) = result {
                        return movie
                    }
                    return nil
                }
            case .failure(let error):
                print("Error fetching search results: \(error)")
            }
        }
    }
    
    //This function adds a movie
    func addMovie(itemID: Int, itemType: String, itemName: String, imageURL: String? = nil, personID: Int? = nil) {
        // Fetch movie details from API
        apiManager.fetchMovieDetails(by: itemID) { result in
            switch result {
            case .success(let movieDetails):
                let movie = Movie(id: Int64(movieDetails.id),
                                  title: movieDetails.title,
                                  description: movieDetails.overview,
                                  directorID: "", // Update this with the actual director ID
                                  actorIDs: "", // Update this with the actual actor IDs
                                  trailerURL: "", // Update this with the actual trailer URL
                                  ratingsAndReviews: "", // Update this with the actual ratings and reviews
                                  posterImageURL: movieDetails.posterPath ?? "")
        
                
                // Insert movie into likedMovies in the database
                do {
                    try dbManager?.insert(movie: movie)
                    
                    // Update the local state variable
                    likedMovies.append(movie)
                } catch {
                    print("Error inserting movie into database: \(error)")
                    // Show an alert with the error message
                }
            case .failure(let error):
                print("Error fetching movie details: \(error)")
                // Show an alert with the error message
            }
        }

    }
    
    //This function adds a person
    func addPerson(itemID: Int, itemType: String, itemName: String, imageURL: String? = nil, personID: Int? = nil) {
        if let personID = personID {
            apiManager.getPersonDetails(personID: personID) { result in
                switch result {
                case .success(let personDetails):
                    
                    let personInfo = APIManager.PersonInfo(id: personDetails.id, name: personDetails.name, imagePath: personDetails.profilePath)

                    // Determine if the person is an actor or director based on their known roles
                    let itemType = personDetails.knownForDepartment.lowercased() == "acting" ? "actor" : "director"

                    // Insert person into favoriteActors or favoriteDirectors in the database
                    do {
                        if itemType == "actor" {
                            try dbManager?.insertPersonPreference(username: username, type: "actor", name: personInfo.name, imageURL: personInfo.imagePath ?? "")
                            favoriteActors.append(personInfo)
                        } else {
                            try dbManager?.insertPersonPreference(username: username, type: "director", name: personInfo.name, imageURL: personInfo.imagePath ?? "")
                            favoriteDirectors.append(personInfo)
                        }
                    } catch {
                        print("Error inserting person into database: \(error)")
                        // Show an alert with the error message
                    }
                        
                    case .failure(let error):
                        print("Error fetching person details: \(error)")
                        // Show an alert with the error message
                    }
                }
            }
    }
}

struct CustomItemViewWithTap: View {
    let movie: Movie
    let onAddButtonPressed: (() -> Void)?
    
    @State private var isMovieDetailsPresented: Bool = false
    
    var body: some View {
        CustomItemView(title: movie.title, imageURL: movie.posterImageURL, onAddButtonPressed: onAddButtonPressed)
            .onTapGesture {
                isMovieDetailsPresented = true
            }
            .sheet(isPresented: $isMovieDetailsPresented) {
                MovieDetailsView(movieId: Int(movie.id))
            }
    }
}



struct CustomItemView: View {
    let title: String
    let imageURL: String?
    let onAddButtonPressed: (() -> Void)?
    
  
    @State private var image: UIImage? = nil
    let apiManager = APIManager()
    
    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 100, height: 150)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 100, height: 150)
                    .foregroundColor(.gray)
            }
            
    
            
            VStack {
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
            }
                
                Spacer()
                
                
                if let onAddButtonPressed = onAddButtonPressed { // Check if onAddButtonPressed is not nil
                    Button(action: {
                        onAddButtonPressed()
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
            
        }
        .onAppear {
            if let imageURL = imageURL {
                apiManager.fetchImage(at: imageURL) { result in
                    switch result {
                    case .success(let fetchedImage):
                        self.image = fetchedImage
                    case .failure(let error):
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}


