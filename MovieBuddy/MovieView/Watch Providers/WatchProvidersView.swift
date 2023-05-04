//
//  WatchProvidersView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/24/23.
//

import SwiftUI

struct WatchProvidersView: View {
    let watchProviders: [WatchProvider]
    let apiManager: APIManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tv")
                Text("Watch Providers")
                    .font(.system(size: 18, weight: .bold))
            }
            if !watchProviders.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(watchProviders, id: \.id) { provider in
                            VStack {
                                if let logoPath = provider.logoPath {
                                    let imageURL = apiManager.getImageURL(at: logoPath)
                                    AsyncImage(url: imageURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 30)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Text(provider.name)
                                }
                            }
                            .frame(width: 80)
                            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .onTapGesture {
                                if let providerURL = provider.providerURL,
                                   let url = URL(string: providerURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No watch providers found")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct WatchProvidersView_Previews: PreviewProvider {
    static var previews: some View {
        WatchProvidersView(watchProviders: [], apiManager: APIManager())
    }
}

