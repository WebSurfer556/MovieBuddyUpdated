//
//  MovieRecommendationButton.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/27/23.
//

import SwiftUI

import SwiftUI

struct MovieRecommendationButton: View {
    let onRecommend: () -> Void
    let isDisabled: Bool

    var body: some View {
        Button(action: onRecommend) {
            Text("Get Movie Recommendations")
        }
        .disabled(isDisabled)
    }
}
