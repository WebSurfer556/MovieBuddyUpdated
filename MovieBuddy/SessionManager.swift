import Foundation
import SQLite

class SessionManager {
    static let shared = SessionManager()
    private var db: Connection
    private let databaseManager = DatabaseManager()
    
    
    init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/moviebuddy.sqlite3")
            
            let users = Table("users")
            let id = Expression<Int64>("id")
            let username = Expression<String>("username")
            
            try db.run(users.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(username)
            })
            
            let chat_messages = Table("chat_messages")
            let content = Expression<String>("content")
            let user_id = Expression<Int64>("user_id")
            
            try db.run(chat_messages.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(content)
                t.column(user_id)
            })
        } catch {
            print("Error creating connection to the database: \(error)")
            do {
                db = try Connection()
            } catch {
                fatalError("Error creating a new connection: \(error)")
            }
        }
    }
    
    func processPreferences(username: String, aiResponse: String) {
        // Parse the AI's response to extract genres, actors, directors, or movie titles.
        // This is a simplified example; you may want to use more sophisticated parsing techniques.
        let preferences = aiResponse.components(separatedBy: ", ")
        
        // Update the user preferences in the SQLite database using the extracted information.
        for preference in preferences {
            let type: String
            if preference.contains("genre") {
                type = "genre"
            } else if preference.contains("actor") {
                type = "actor"
            } else if preference.contains("director") {
                type = "director"
            } else if preference.contains("movie") {
                type = "movie"
            } else {
                continue
            }
            // Save the preference to the SQLite database.
            do {
                try DatabaseManager.shared?.insertPreference(username: username, type: type, value: preference)
            } catch {
                print("Error saving preference: \(error)")
            }
        }
    }


    



    func saveMessage(userID: Int64, content: String) {
        let chatMessage = ChatMessage(id: Int64(Date().timeIntervalSince1970 * 1000), userID: userID, content: content, created_at: Date(), role: "user")
        do {
            try databaseManager?.insert(chatMessage: chatMessage)
            print("Message saved: \(chatMessage)")
        } catch {
            print("Error saving message: \(error)")
        }
    }



    func createUser(username: String) -> Int64? {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let usernameColumn = Expression<String>("username")
        
        do {
            let query = users.select(id).filter(usernameColumn == username)
            let result = try db.pluck(query)
            if result == nil {
                let insert = users.insert(usernameColumn <- username)
                let userID = try db.run(insert)
                return userID
            } else {
                return result?[id]
            }
        } catch {
            print("Error executing SQL query: \(error)")
            return nil
        }
    }



    func getUserID(username: String) -> Int64? {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let username = Expression<String>("username")

        do {
            let query = users.select(id).filter(username == username)
            let result = try db.pluck(query)
            return result?[id]
        } catch {
            print("Error executing SQL query: \(error)")
            return nil
        }
    }

   
    
    func getPreviousChatMessages(userID: Int64) throws -> [ChatMessage] {
        let chat_messages = Table("chat_messages")
        let id = Expression<Int64>("id")
        let user_id = Expression<Int64>("user_id")
        let content = Expression<String>("content")
        let created_at = Expression<Date>("created_at")
        let role = Expression<String>("role")

        let query = chat_messages.filter(user_id == userID).select(id, content, created_at, role).order(created_at.asc)

        var messages: [ChatMessage] = []

        for row in try db.prepare(query) {
            let message = ChatMessage(id: row[id], userID: userID, content: row[content], created_at: row[created_at], role: row[role])
            messages.append(message)
        }

        return messages
    }


    
    



    func sendAPIRequest(username: String, message: String) -> String {
        let sessionManager = SessionManager()

        guard let userID = sessionManager.getUserID(username: username) ?? sessionManager.createUser(username: username) else {
            return "Error: User not found."
        }
        sessionManager.saveMessage(userID: userID, content: message)

        var chatHistory: [ChatMessage] = []
        do {
            chatHistory = try sessionManager.getPreviousChatMessages(userID: userID)
        } catch {
            print("Error getting chat history: \(error)")
        }

        var messages: [APIManager.Message] = []

        for (index, chatMessage) in chatHistory.enumerated() {
                let role = chatMessage.role // Use the role from the chatMessage object
                messages.append(APIManager.Message(role: role, content: chatMessage.content))
            }

        // Append the current user message to the messages array
        messages.append(APIManager.Message(role: "user", content: message))

        let data: [String: Any] = ["model": "gpt-3.5-turbo", "messages": messages]

        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let semaphore = DispatchSemaphore(value: 0)
        var result = ""

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Error sending API request: \(error)")
                        result = "Error sending API request."
                        semaphore.signal()
                    } else {
                        if let data = data, let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let choices = responseData["choices"] as? [[String: String]], let text = choices[0]["text"] {
                            result = text
                            semaphore.signal()
                        } else {
                            result = "Error sending API request."
                            semaphore.signal()
                        }
                    }
                }
                task.resume()
                semaphore.wait()
                return result
            }
        }


        struct ApiResponse: Codable {
            let choices: [Choice]
        }

        struct Choice: Codable {
            let text: String
        }

                                                                            


