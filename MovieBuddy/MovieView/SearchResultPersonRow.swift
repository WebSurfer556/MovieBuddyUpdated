//
//  SearchResultPersonRow.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 5/2/23.
//

import SwiftUI

struct SearchResultPersonRow: View {
    let person: APIManager.Person
    let apiManager = APIManager()
    
    
    let onAddButtonPressed: () -> Void
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        CustomItemView(title: person.name, imageURL: person.profilePath, onAddButtonPressed: onAddButtonPressed)
        
    }
}
