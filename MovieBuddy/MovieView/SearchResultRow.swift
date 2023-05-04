//
//  SearchResultRow.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 5/2/23.
//

import SwiftUI

struct SearchResultRow: View {
    let movie: APIManager.Movie
    let apiManager = APIManager()
    
    let onAddButtonPressed: () -> Void
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        CustomItemView(title: movie.title, imageURL: movie.posterPath, onAddButtonPressed: onAddButtonPressed)
    }
}
