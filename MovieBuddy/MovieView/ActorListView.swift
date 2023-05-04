//
//  ActorListView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/24/23.
//

import SwiftUI

struct ActorListView: View {
    let movieDetails: APIManager.MovieDetails?
    
    var body: some View {
        if let movieDetails = movieDetails {
            Text("Actors")
                .font(.system(size: 18, weight: .bold))
            
            ForEach(movieDetails.credits.cast.prefix(5), id: \.name) { actor in
                Text("\(actor.name) as \(actor.character)")
                    .font(.system(size: 14))
            }
        }
    }
}


