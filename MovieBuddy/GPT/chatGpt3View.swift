import SwiftUI
import Alamofire

struct ChatView: View {
    
    //This is the username for the session
    let username: String
    
    //keeps track of this is the first time it is calling the initial prompt
    @State private var initialPrompt = true

    //used for the userID fetching preferences
    @State private var userID: Int64?
    
    //state var for storing movie names
    @State private var movieNames: [String] = []
    
    //makes sure the APi request is finished for movie names
    @State private var isExtractingMovieNames = false


    @State private var userInput: String = ""
    @State private var gptResponse: String = ""
    @State private var isLoading: Bool = false
    @State private var previousChats = [APIManager.Message]()
    
    //initial question for the user
    @State private var initialQuestion = "What kind of movie are you feeling today?"

    var apiManager = APIManager()
    
    var body: some View {
        VStack {
            // Add a Spacer to push the input components to the bottom
            Spacer()
            
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    PreviousChatsView(initialQuestion: initialQuestion, previousChats: previousChats, isLoading: $isLoading, movieNames: movieNames, isExtractingMovieNames: $isExtractingMovieNames)
                        .onChange(of: previousChats.count) { _ in
                            // Scroll to the most recent message
                            scrollViewProxy.scrollTo(previousChats.count - 1, anchor: .bottom)
                        }
                }
            }
            
            VStack {
                ChatInputView(userInput: $userInput, onSend: {
                    isLoading = true
                    var messages = previousChats
                    
                    // Check if the user's input contains a recommendation keyword
                    let shouldRecommend = apiManager.userWantsRecommendation(userInput)

                                        
                    // Append the user's input message to previousChats
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.5)) {
                                self.previousChats.append(APIManager.Message(role: "user", content: userInput))
                            }
                        }
                    
                    // Then, append the user's input message.
                    messages.append(APIManager.Message(role: "user", content: userInput))
                    
                    print("This is the messages array: \(messages) \n")
                    
                    // If the user requested a recommendation, add a system message to prompt the AI for a recommendation
                    if shouldRecommend {
                        let getUserPreferences = try? DatabaseManager.shared?.getUserPreferences(userID: userID!)

                        let userPreferencesString = "genres: \(getUserPreferences?.genres ?? ""), actors: \(getUserPreferences?.actors ?? ""), directors: \(getUserPreferences?.directors ?? ""), movies: \(getUserPreferences?.movies ?? "")"

                        let prompt = "Considering the user's preferences, which include a liking for \(userPreferencesString), can you recommend a movie that perfectly aligns with their taste and interests?"

                        let recommendationMessage = APIManager.Message(role: "system", content: prompt)
                        messages.append(recommendationMessage)
                    }

                    // ... existing code for sending user message ...
                    apiManager.requestGPT3ChatCompletion(username: username, messages: messages, initialPrompt: initialPrompt) { result in
                           switch result {
                           case .success(let response):
                               // Inside the .success case of the result
                               initialPrompt = false

                               gptResponse = response
                               DispatchQueue.main.async {
                                   withAnimation(.easeInOut(duration: 0.5)) {
                                                   self.previousChats.append(APIManager.Message(role: "assistant", content: response))
                                               }
                                           }
                               print("GPT-3.5 response: \(response)")
                               
                               //updates the users preferences with the responce
                               // Call gatherPreferences after receiving a response from the AI
                               apiManager.gatherPreferences(username: username, userResponse: response) { result in
                                   switch result {
                                   case .success(let updatedResponse):
                                       print("User preferences updated: \(updatedResponse)")
                                   case .failure(let error):
                                       print("Error updating user preferences: \(error.localizedDescription)")
                                   }
                               }
                               
                               
                               //This handles the getting of movie names
                               self.isExtractingMovieNames = true // Add this line
                               self.movieNames = []
                               apiManager.extractMovieNames(from: response) { movieNames, error in
                                   DispatchQueue.main.async {
                                       self.isExtractingMovieNames = false // Add this line
                                       if let movieNames = movieNames {
                                           self.movieNames = movieNames
                                       } else {
                                           print("Error extracting movie names: \(error?.localizedDescription ?? "Unknown error")")
                                       }
                                   }
                               }
                           case .failure(let error):
                               print("Error: \(error.localizedDescription)")
                           }
                           isLoading = false
                       }
                }, isLoading: isLoading)
            }
            .padding()
        }.onAppear {
            do {
                userID = try DatabaseManager.shared?.getUserID(username: username)
            } catch {
                print("Error fetching user ID: \(error)")
            }
        }
    }
}

