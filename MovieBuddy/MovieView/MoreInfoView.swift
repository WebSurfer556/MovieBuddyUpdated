//
//  MoreInfoView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/23/23.
//

import SwiftUI

struct MoreInfoView: View {
    let movieDetails: APIManager.MovieDetails?
    let posterImage: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            if let movieDetails = movieDetails {
                VStack(alignment: .leading, spacing: 16) {
                    if let posterImage = posterImage {
                        ZStack {
                            Image(uiImage: posterImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: geometry.size.width * 0.6)
                                .clipped()
                            
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: geometry.size.width * 0.6)
                        }
                    }
                    
                    Text("Description")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text("\(movieDetails.overview)")
                        .font(.system(size: 14))
                    
                    if let director = movieDetails.credits.crew.first(where: { $0.job == "Director" }) {
                        Text("Director: \(director.name)")
                            .font(.system(size: 14))
                    }
                    
                    //Display the actors list
                    ActorListView(movieDetails: movieDetails)
                }
                .padding()
            } else {
                Text("No movie details available")
            }
        }
    }
}

