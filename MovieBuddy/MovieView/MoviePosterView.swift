//
//  MoviePosterView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/24/23.
//

import SwiftUI

struct MoviePosterView: View {
    let posterImage: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            if let posterImage = posterImage {
                Image(uiImage: posterImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: geometry.size.width * 0.6)
                    .clipped()
                
            }
        }
    }
}

