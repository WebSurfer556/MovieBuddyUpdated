//
//  YouTubeVideoView.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/23/23.
//


import SwiftUI
import WebKit

struct YouTubeVideoView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.allowsInlineMediaPlayback = true
        webViewConfiguration.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)") else { return }
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}
