//
//  APImanager.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/20/23.
//

import Foundation
import Alamofire
import UIKit

class APIManager {
    //instance of session manager
    let sessionManager = SessionManager()
    
    let systemMessages: [String: String] = [
        "initial": "You are an AI movie expert with extensive knowledge of films across various genres and decades. Your task is to provide personalized movie recommendations based on user preferences and specific requests. Currently, your task is to ask the user a series of questions to learn about their favorite movies, genres, actors, and directors before making a recommendation. Remember to collect all of the information on the above. After gathering enough information, proactively ask if the user wants a movie recommendation. If the user doesn't want a recommendation yet, adapt your behavior and continue asking questions or engage in other movie-related discussions. Start by asking the user about the genre they are interested in, then ask about their favorite movies within that genre, and finally ask about their preferred actors and directors.",
        
        "followUp": "Adapt your behavior based on user responses. Only recomend movies when explicitly asked for a recomendation by the user. For example they might say one of these phrases recommend, suggestion, what should, which movie, what movie.  Engage the user in other movie-related discussions. Make the conversation more dynamic and interactive. Before making a recomendation ask the user about different direcotrs or actors in the certain Genere they are looking for. Ask them if they have seen some of the most popular movies in that genere to what they think about them."
    ]

    
    //struct for messaging chat gpt
    struct Message: Identifiable {
            var id = UUID()
            var role: String
            var content: String
        }

    
    
    //struct for handling movie db responce
    struct Movie: Codable {
        let id: Int
        let title: String
        let overview: String
        let releaseDate: String
        let posterPath: String?
        let voteAverage: Double
        let budget: Int?
        let genres: [Genre]?
        let runtime: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case overview
            case releaseDate = "release_date"
            case posterPath = "poster_path"
            case voteAverage = "vote_average"
            case budget
            case genres
            case runtime
        }
    }

    struct Genre: Codable {
        let id: Int
        let name: String
    }
    
    struct MovieDetails: Codable, Identifiable {
        let id: Int
        let title: String
        let overview: String
        let posterPath: String?
        let voteAverage: Double
        let credits: Credits

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case overview
            case posterPath = "poster_path"
            case voteAverage = "vote_average"
            case credits
        }
    }


    struct Credits: Codable {
        let cast: [Actor]
        let crew: [CrewMember]
    }

    struct Actor: Codable {
        let name: String
        let character: String
    }

    struct CrewMember: Codable {
        let name: String
        let job: String
    }
    
    struct MovieCredits: Codable {
        let cast: [Actor]
        let crew: [CrewMember]
    }

    struct Person: Codable {
        let id: Int
        let name: String
        let profilePath: String?
        let knownFor: [MultiSearchResult]?
        let adult: Bool
        let popularity: Double
        let job: String? // Make this field optional
        let knownForDepartment: String // Add this field
        
        enum CodingKeys: String, CodingKey {
            case id, name, adult, popularity, job
            case profilePath = "profile_path"
            case knownFor = "known_for"
            case knownForDepartment = "known_for_department" // Add this case
        }
    }
    
    struct PersonInfo {
        let id: Int
        let name: String
        let imagePath: String?
    }

    
    struct FindResponse: Codable {
        let page: Int
        let results: [MultiSearchResult]
        let totalPages: Int
        let totalResults: Int

        enum CodingKeys: String, CodingKey {
            case page
            case results
            case totalPages = "total_pages"
            case totalResults = "total_results"
        }
    }
    
    
    enum MultiSearchResult: Codable {
        case movie(APIManager.Movie)
        case person(Person)
        case unknown

        enum CodingKeys: String, CodingKey {
            case mediaType = "media_type"
        }

        init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let mediaType = try container.decode(String.self, forKey: .mediaType)
                let singleValueContainer = try decoder.singleValueContainer()

                switch mediaType {
                case "movie":
                    let movie = try singleValueContainer.decode(APIManager.Movie.self)
                    self = .movie(movie)
                case "person":
                    let person = try singleValueContainer.decode(Person.self)
                    self = .person(person)
                default:
                    self = .unknown
                }
            }

        func encode(to encoder: Encoder) throws {
               var container = encoder.container(keyedBy: CodingKeys.self)
               switch self {
               case .movie(let movie):
                   try container.encode("movie", forKey: .mediaType)
                   try movie.encode(to: encoder)
               case .person(let person):
                   try container.encode("person", forKey: .mediaType)
                   try person.encode(to: encoder)
               case .unknown:
                   break
               }
           }
    }


    // Add structs for Movie, Person, and TVShow



    //gathers the users preferences
    func gatherPreferences(username: String, userResponse: String, completionHandler: @escaping (Result<String, Error>) -> Void) {
        let extractionPrompt = "Extract the user's movie preferences from this conversation: \(userResponse)"
        
        requestGPT3ChatCompletion(username: username, messages: [APIManager.Message(role: "system", content: extractionPrompt)]) { result in
            switch result {
            case .success(let extractedPreferences):
                // Process the AI's response and update the user preferences in the database
                self.sessionManager.processPreferences(username: username, aiResponse: extractedPreferences)
                completionHandler(.success("User preferences updated successfully"))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func extractMovieNames(from text: String, completion: @escaping ([String]?, Error?) -> Void) {
        let prompt = "Please find and list all movie names mentioned in the following text: \"\(text)\", If you find any list them in a numbered list style starting with 1. and followed by a space:  . If there are none, just say 'No movie names mentioned.'"


        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(Constants.openAI_APIKey)"
        ]
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a helpful assistant. Your job to to read through the provided text and list out if there are any movie names mentioned. If there are none just say no movie names mentioned. If you find them please list them seperated by commas."],
            ["role": "user", "content": prompt]
        ]
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages
        ]
        
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let message = firstChoice["message"] as? [String: Any],
                           let content = message["content"] as? String {
                        
                        // Call the extractMovieNames function with the content as an argument
                        let movieNames = self.parseMovieNames(from: content)
                        
                       
                        completion(movieNames.filter { $0.lowercased() != "no movie names mentioned." }, nil)
                    } else {
                        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "no movie names mentioned"]))
                    }
                case .failure(let error):
                    print("Failure in extractMovieNames: \(error)") // Debug print statement
                    completion(nil, error)
                }
            }
    }

    
    func parseMovieNames(from text: String) -> [String] {
        // Define the regex pattern to match movie names
        // The pattern matches a number followed by a period, a space, and then the movie name (excluding the year)
        let regexPattern = "\\d+\\.\\s+([^\\(]+)"
        
        // Initialize an empty array to store movie names
        var movieNames: [String] = []
        
        // Split the content string into lines
        let lines = text.split(separator: "\n")

        for line in lines {
            do {
                // Create an NSRegularExpression object using the regex pattern
                let regex = try NSRegularExpression(pattern: regexPattern, options: [])
                
                // Convert the input text to an NSString, which is required for using NSRange
                let nsText = line as NSString
                
                // Find all matches of the regex pattern in the input text
                let matches = regex.matches(in: String(line), options: [], range: NSRange(location: 0, length: nsText.length))

                // Iterate through the matches
                for match in matches {
                    // Get the NSRange of the movie name (group 1 in the regex pattern)
                    let matchedMovieNameRange = match.range(at: 1)
                    
                    // Extract the movie name using the NSRange
                    let movieName = nsText.substring(with: matchedMovieNameRange).trimmingCharacters(in: .whitespaces)
                    
                    // Append the movie name to the movieNames array
                    movieNames.append(movieName)
                }
            } catch {
                // If an error occurs while parsing movie names, print the error
                print("Error parsing movie names: \(error.localizedDescription)")
            }
        }
        
        
        // Return the array of movie names
        return movieNames
    }
    
    
    //Check is the user has requested a recomendation
    func userWantsRecommendation(_ message: String) -> Bool {
        print("The User wants a recomendation")
        let lowercasedMessage = message.lowercased()
        let recommendationKeywords = ["recommend", "suggestion", "what should", "which movie", "what movie"]
        let positiveResponses = ["yes", "sure", "absolutely", "of course", "please", "yeah", "yep", "yup"]
        
        var recommendationCount = 0
        var positiveResponseCount = 0
        
        for keyword in recommendationKeywords {
            if lowercasedMessage.contains(keyword) {
                recommendationCount += 1
            }
        }
        
        for response in positiveResponses {
            if lowercasedMessage.contains(response) {
                positiveResponseCount += 1
            }
        }
        
        let totalScore = recommendationCount + positiveResponseCount
        let threshold = 3 // You can adjust this value as needed to fine-tune the behavior
        
        return totalScore >= threshold
    }








    
    // ...
    func requestGPT3ChatCompletion(username: String, messages: [Message], initialPrompt: Bool = false, completion: @escaping (Result<String, Error>) -> Void) {
        let sessionManager = SessionManager.shared

        do {
            guard let userID = sessionManager.getUserID(username: username) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                return
            }
            
            
            
            let chatHistory = try sessionManager.getPreviousChatMessages(userID: userID)

            var previousChats = messages
            
            //print("User message appended: \n", previousChats)

            
            //creates the intial prompt and tells the AI exactly what it should be doing and what its role is
            if initialPrompt {
                if let initialSystemMessageContent = systemMessages["initial"] {
                    let initialSystemMessage = Message(role: "system", content: initialSystemMessageContent)
                    previousChats.append(initialSystemMessage)
                    

                }
            }

            

            // Add the chat history to the dictionary.
            for chatMessage in chatHistory {
                let role = chatMessage.role // Use the role from the chatMessage object
                previousChats.append(APIManager.Message(role: role, content: chatMessage.content))
            }

            //checks if the user is asking for a recomendation
            if let lastUserMessage = previousChats.last(where: { $0.role == "user" }) {
                if !userWantsRecommendation(lastUserMessage.content) {
                    print("User does not want a recommendation yet")
                    if let followUpSystemMessageContent = systemMessages["followUp"] {
                        let followUpSystemMessage = Message(role: "system", content: followUpSystemMessageContent)
                        previousChats.append(followUpSystemMessage)
                        //print("Follow-up system message appended: \n", followUpSystemMessage)
                    }
                }
            }



            // Make the API request.
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
           


            let headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(Constants.openAI_APIKey)"
            ]

            let parameters: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": previousChats.map { ["role": $0.role, "content": $0.content] }
            ]

           


            var firstChoice: [String: Any]?
            
            


            AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .responseJSON { response in
                    

                    switch response.result {
                    case .success(let data):
                        if let json = data as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           choices.count > 0 {
                            let firstChoice = choices.first
                            
                            if let message = firstChoice?["message"] as? [String: Any],
                               let content = message["content"] as? String {
                                // Save the assistant's reply in the database
                                let assistantMessage = ChatMessage(id: Int64(Date().timeIntervalSince1970 * 1000), userID: userID, content: content, created_at: Date(), role: "assistant")
                                do {
                                    try DatabaseManager.shared?.insert(chatMessage: assistantMessage)
                                } catch {
                                    print("Error saving assistant's message: \(error)")
                                }
                                completion(.success(content))
                                
                            } else if let finishReason = firstChoice?["finish_reason"] as? String, finishReason == "length" {
                                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Incomplete GPT-3.5 response"])))
                            } else {
                                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse GPT-3.5 response"])))
                            }
                        } else {
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No choices returned"])))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }

    }
    
    //API Calls for movie DB this gets the movies ID
    func searchMovieByName(_ name: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let url = "https://api.themoviedb.org/3/search/movie"
        
        let parameters: [String: Any] = [
            "api_key": Constants.movieDB_APIKey,
            "query": name
        ]
        
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: jsonData)

                        if let firstResult = searchResponse.results.first {
                            completion(.success(firstResult.id))
                        } else {
                            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse movie search response"])))
                        }
                    } catch {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse movie search response"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    //This will get details and be able to display them correctly
    func getPersonDetails(personID: Int, completion: @escaping (Result<Person, Error>) -> Void) {
        let urlString = "https://api.themoviedb.org/3/person/\(personID)?api_key=\(Constants.movieDB_APIKey)&language=en-US&append_to_response=movie_credits"

        AF.request(urlString).validate().responseDecodable(of: Person.self) { response in
            switch response.result {
            case .success(let personDetails):
                completion(.success(personDetails))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    // This searches the movies names and will display multiple results
    func find(id: String, externalSource: String, completion: @escaping (Result<FindResponse, Error>) -> Void) {
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id
        let urlString = "https://api.themoviedb.org/3/search/multi?api_key=\(Constants.movieDB_APIKey)&language=en-US&query=\(encodedId)"


        AF.request(urlString).validate().responseDecodable(of: FindResponse.self) { response in
            switch response.result {
            case .success(let findResponse):
                completion(.success(findResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    //function for extracting the users preferences
    func extractPreferences(username: String, userResponse: String, completion: @escaping (Result<String, Error>) -> Void) {
        let extractionPrompt = "Extract the user's preferences for genres, actors, directors, and movies from the following response: "
        let constructedMessage = extractionPrompt + userResponse
        let message = APIManager.Message(role: "user", content: constructedMessage)

        requestGPT3ChatCompletion(username: username, messages: [message]) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }


    struct SearchResponse: Codable {
        let results: [Movie]
    }

    
    //Function to get the movie watch provieders
    func getMovieWatchProviders(movieID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let url = "https://api.themoviedb.org/3/movie/\(movieID)/watch/providers"

        let parameters: [String: Any] = [
            "api_key": Constants.movieDB_APIKey
        ]

        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                       let results = json["results"] as? [String: Any] {
                       
                        
                        completion(.success(results))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse movie watch providers response"])))
                    }
                case .failure(let error):
                    print("Error in watch providers API: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
    }

    
    //Function to get the movie trailer using a 'get videos' request
    func getMovieVideos(movieID: Int, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let url = "https://api.themoviedb.org/3/movie/\(movieID)/videos"

        let parameters: [String: Any] = [
            "api_key": Constants.movieDB_APIKey,
            "language": "en-US"
        ]

        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                       let results = json["results"] as? [[String: Any]] {
                        completion(.success(results))
                    } else {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse movie videos response"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }


    //Gets a url for showing the providers
    func getImageURL(at path: String) -> URL {
        return URL(string: "https://image.tmdb.org/t/p/w200\(path)")!
    }
    
    // a function to fetch the movie details from the struct this also will show watch provider information
    func fetchMovieDetailsWithProviders(by id: Int, completion: @escaping (Result<(MovieDetails, [String: Any]), Error>) -> Void) {
        let group = DispatchGroup()
        
        var movieDetailsResult: Result<MovieDetails, Error>?
        var watchProvidersResult: Result<[String: Any], Error>?
        
        group.enter()
        fetchMovieDetails(by: id) { result in
            movieDetailsResult = result
            group.leave()
        }
        
        group.enter()
        getMovieWatchProviders(movieID: id) { result in
            watchProvidersResult = result
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let movieDetailsResult = movieDetailsResult, let watchProvidersResult = watchProvidersResult {
                switch (movieDetailsResult, watchProvidersResult) {
                case (.success(let movie), .success(let providers)):
                    completion(.success((movie, providers)))
                case (.failure(let error), _):
                    completion(.failure(error))
                case (_, .failure(let error)):
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch movie details and watch providers"])))
            }
        }
    }

    
    
    //gets the movie details so we can display them
    func fetchMovieDetails(by movieId: Int, completion: @escaping (Result<MovieDetails, Error>) -> Void) {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(Constants.movieDB_APIKey)&append_to_response=credits"

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let decoder = JSONDecoder()
                let movieDetails = try decoder.decode(MovieDetails.self, from: data)
                completion(.success(movieDetails))
            } catch {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse movie details response"])))
            }
        }.resume()
    }


    //Gets the movie poster
    func fetchImage(at path: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let baseURL = "https://image.tmdb.org/t/p/w500/"
        let urlString = baseURL + path

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            if let image = UIImage(data: data) {
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image data"])))
            }
        }.resume()
    }
}





