//
//  WatchProvider.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/24/23.
//

import Foundation

struct WatchProvider: Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let providerURL: String?

    init?(json: [String: Any]) {
        guard let id = json["provider_id"] as? Int,
              let name = json["provider_name"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.logoPath = json["logo_path"] as? String
        self.providerURL = json["link"] as? String
    }
}
