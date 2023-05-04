//
//  DatabaseManager.swift
//  MovieBuddy
//
//  Created by Nic Krystynak on 4/20/23.
//

import Foundation
import SQLite

// MARK: - DatabaseManager class

//Implement the database manager class
//This is a single class that handles connections to the sqlite data base and provides methods for performing CRUD operations on the data model

class DatabaseManager {
    //This initizalies the database manager. The shared property is a singleton instance of the DatabaseManager class. db is a private property representing the connection to the SQLite database.
    static let shared = DatabaseManager()
    private let db: Connection
    private let version: Int32 = 2

    
    init?() {
        // Set up a connection to the database
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }

        do {
            db = try Connection("\(path)/moviebuddy.sqlite3")
            try setUserVersion()
            try updateSchema()
            try createTables()
        } catch {
            print("Error creating connection to the database: \(error)")
            return nil
        }
    }
    
    
    //function to set the DB version
    private func setUserVersion() throws {
        let userVersion = try db.scalar("PRAGMA user_version") as? Int32 ?? 0
           if userVersion < version {
               try db.run("PRAGMA user_version = \(version)")
           }
    }
        
    //function to handle schema updates
    private func updateSchema() throws {
        let userVersion = try db.scalar("PRAGMA user_version") as? Int32 ?? 0
        
       
        if userVersion < 2 {
            // Check if the chat_messages_old table exists.
            let oldTableExists = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table' AND name='chat_messages_old'") as? Int32 ?? 0

            

            
            // If it exists, drop the table.
            if oldTableExists > 0 {
                let dropOldTableSQL = "DROP TABLE chat_messages_old"
                try db.run(dropOldTableSQL)
                print("Dropped chat_messages_old table")
            }

            let renameTableSQL = "ALTER TABLE chat_messages RENAME TO chat_messages_old"
            try db.run(renameTableSQL)

            let createTableSQL = """
            CREATE TABLE chat_messages (
                id INTEGER PRIMARY KEY,
                user_id INTEGER,
                content TEXT,
                created_at TEXT,
                role TEXT,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
            """
            try db.run(createTableSQL)

            let copyDataSQL = """
            INSERT INTO chat_messages (id, user_id, content, role)
            SELECT id, user_id, content, role FROM chat_messages_old
            """
            try db.run(copyDataSQL)

            let dropOldTableSQL = "DROP TABLE chat_messages_old"
            try db.run(dropOldTableSQL)
        }
    }






    // MARK: - Create tables
    //This private method creates the tables for each data model in the SQLite database: movies, users, recommendations, and chat_messages. It defines the columns, primary keys, and foreign keys for each table.
    
    private func createTables() throws {
        let movies = Table("movies")
        let users = Table("users")
        let recommendations = Table("recommendations")
        let chat_messages = Table("chat_messages")
        let user_preferences = Table("user_preferences")
        let directors = Table("directors")
        let actors = Table("actors")
        


        try db.run(movies.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<String>("title"))
            t.column(Expression<String>("description"))
            t.column(Expression<String>("trailer_url"))
            t.column(Expression<String>("ratings_and_reviews"))
            t.column(Expression<String>("poster_image_url"))
            t.column(Expression<String>("director_id"))
            t.column(Expression<String>("actor_ids"))
        })

        try db.run(users.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<String>("username"))
            t.column(Expression<String>("preferences"))
        })

        try db.run(recommendations.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<Int64>("user_id"))
            t.column(Expression<Int64>("movie_id"))
            t.column(Expression<Date>("created_at"))
            t.foreignKey(Expression<Int64>("user_id"), references: users, Expression<Int64>("id"))
            t.foreignKey(Expression<Int64>("movie_id"), references: movies, Expression<Int64>("id"))
        })

        try db.run(chat_messages.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<Int64>("user_id"))
            t.column(Expression<String>("content"))
            t.column(Expression<Date>("created_at"))
            t.column(Expression<String>("role")) // Add this line
            t.foreignKey(Expression<Int64>("user_id"), references: users, Expression<Int64>("id"))
        })
        
        try db.run(user_preferences.create(ifNotExists: true) { t in
                    t.column(Expression<Int64>("user_id"), primaryKey: true)
                    t.column(Expression<String>("genres"), defaultValue: "")
                    t.column(Expression<String>("actors"), defaultValue: "")
                    t.column(Expression<String>("directors"), defaultValue: "")
                    t.column(Expression<String>("movies"), defaultValue: "")
                    t.foreignKey(Expression<Int64>("user_id"), references: users, Expression<Int64>("id"))
                })
        
        
        try db.run(directors.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<String>("name"))
        })

        try db.run(actors.create(ifNotExists: true) { t in
            t.column(Expression<Int64>("id"), primaryKey: true)
            t.column(Expression<String>("name"))
        })

    }

    // MARK: - Movies helper methods

    func insertPersonPreference(username: String, type: String, name: String, imageURL: String) throws {
        let users = Table("users")
        let userId = Expression<Int64>("id")
        let usernameColumn = Expression<String>("username")

        let user_preferences = Table("user_preferences")
        let user_id = Expression<Int64>("user_id")
        let actorsColumn = Expression<String>("actors")
        let directorsColumn = Expression<String>("directors")

        // Get the user ID from the users table.
        guard let userID = try db.pluck(users.filter(usernameColumn == username))?[userId] else {
            throw NSError(domain: "Error: User not found.", code: -1, userInfo: nil)
        }

        // Determine the appropriate column for the preference.
        let preferenceColumn: Expression<String>
        switch type {
        case "actor":
            preferenceColumn = actorsColumn
        case "director":
            preferenceColumn = directorsColumn
        default:
            throw NSError(domain: "Error: Invalid preference type.", code: -1, userInfo: nil)
        }

        // Insert the new preference value into the database.
        let query = user_preferences.filter(user_id == userID)
        if let currentPreferences = try db.pluck(query)?[preferenceColumn] {
            let newValue = "\(name)|\(imageURL)" // Combine name and imageURL using a separator (e.g., '|')
            let updatedPreferences = currentPreferences.isEmpty ? newValue : "\(currentPreferences), \(newValue)"
            try db.run(query.update(preferenceColumn <- updatedPreferences))
        } else {
            try insertUserPreferences(userID: userID, genres: "", actors: type == "actor" ? "\(name)|\(imageURL)" : "", directors: type == "director" ? "\(name)|\(imageURL)" : "", movies: "")
        }
    }
    
    func insert(movie: Movie) throws {
        let movies = Table("movies")
        let id = Expression<Int64>("id")
        let title = Expression<String>("title")
        let description = Expression<String>("description")
        let director_id = Expression<String>("director_id")
        let actor_ids = Expression<String>("actor_ids")
        let trailer_url = Expression<String>("trailer_url")
        let ratings_and_reviews = Expression<String>("ratings_and_reviews")
        let poster_image_url = Expression<String>("poster_image_url")

        let insert = movies.insert(id <- movie.id,
                                    title <- movie.title,
                                    description <- movie.description,
                                   director_id <- movie.directorID,
                                   actor_ids <- movie.actorIDs,
                                    trailer_url <- movie.trailerURL,
                                    ratings_and_reviews <- movie.ratingsAndReviews,
                                    poster_image_url <- movie.posterImageURL)

        try db.run(insert)
    }


    // Implement helper methods for Movie
    // MARK: - Movies helper methods

    func queryAllMovies() throws -> [Movie] {
        let movies = Table("movies")
        let id = Expression<Int64>("id")
        let title = Expression<String>("title")
        let description = Expression<String>("description")
        let director_id = Expression<String>("director_id")
        let actor_ids = Expression<String>("actor_ids")
        let trailer_url = Expression<String>("trailer_url")
        let ratings_and_reviews = Expression<String>("ratings_and_reviews")
        let poster_image_url = Expression<String>("poster_image_url")
        
        var movieList: [Movie] = []
        
        for row in try db.prepare(movies) {
            let movie = Movie(id: row[id],
                              title: row[title],
                              description: row[description],
                              directorID: row[director_id],
                              actorIDs: row[actor_ids],
                              trailerURL: row[trailer_url],
                              ratingsAndReviews: row[ratings_and_reviews],
                              posterImageURL: row[poster_image_url])
            movieList.append(movie)
        }
        
        return movieList
    }

    

    // MARK: - Users helper methods
    func insert(user: User) throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let username = Expression<String>("username")
        let preferences = Expression<String>("preferences")

        let insert = users.insert(id <- user.id,
                                  username <- user.username,
                                  preferences <- user.preferences)

        try db.run(insert)
    }


    // Implement helper methods for User

    // MARK: - Recommendations helper methods
    func insert(recommendation: Recommendation) throws {
            let recommendations = Table("recommendations")
            let id = Expression<Int64>("id")
            let user_id = Expression<Int64>("user_id")
            let movie_id = Expression<Int64>("movie_id")
            let created_at = Expression<Date>("created_at")

            let insert = recommendations.insert(id <- recommendation.id,
                                                user_id <- recommendation.userID,
                                                movie_id <- recommendation.movieID,
                                                created_at <- recommendation.created_at)

            try db.run(insert)
        }

    // Implement helper methods for Recommendation

    // MARK: - Chat Messages helper methods
    func insert(chatMessage: ChatMessage) throws {
            let chat_messages = Table("chat_messages")
            let id = Expression<Int64>("id")
            let user_id = Expression<Int64>("user_id")
            let content = Expression<String>("content")
            let created_at = Expression<Date>("created_at")
            let role = Expression<String>("role") // Add this line
          

        let insert = chat_messages.insert(id <- chatMessage.id,
                                          user_id <- chatMessage.userID,
                                          content <- chatMessage.content,
                                          created_at <- chatMessage.created_at,
                                          role <- chatMessage.role) // Add this line)

            try db.run(insert)
        }
    
    // MARK: - User Preferences helper methods
    

       func insertUserPreferences(userID: Int64, genres: String = "", actors: String = "", directors: String = "", movies: String = "") throws {
           let user_preferences = Table("user_preferences")
           let user_id = Expression<Int64>("user_id")
           let genresColumn = Expression<String>("genres")
           let actorsColumn = Expression<String>("actors")
           let directorsColumn = Expression<String>("directors")
           let moviesColumn = Expression<String>("movies")

           let insert = user_preferences.insert(user_id <- userID,
                                                genresColumn <- genres,
                                                actorsColumn <- actors,
                                                directorsColumn <- directors,
                                                moviesColumn <- movies)

           try db.run(insert)
       }
    
    

    //update teh user preferences
    func updateUserPreferences(userID: Int64, genres: String? = nil, actors: String? = nil, directors: String? = nil, movies: String? = nil) throws {
            let user_preferences = Table("user_preferences")
            let user_id = Expression<Int64>("user_id")
            let genresColumn = Expression<String>("genres")
            let actorsColumn = Expression<String>("actors")
            let directorsColumn = Expression<String>("directors")
            let moviesColumn = Expression<String>("movies")

            let query = user_preferences.filter(user_id == userID)

            if let newGenres = genres {
                try db.run(query.update(genresColumn <- newGenres))
            }

            if let newActors = actors {
                try db.run(query.update(actorsColumn <- newActors))
            }

            if let newDirectors = directors {
                try db.run(query.update(directorsColumn <- newDirectors))
            }

            if let newMovies = movies {
                try db.run(query.update(moviesColumn <- newMovies))
            }
        }
    
    //gets the user preferences
    func getUserPreferences(userID: Int64) throws -> (genres: String, actors: String, directors: String, movies: String)? {
            let user_preferences = Table("user_preferences")
            let user_id = Expression<Int64>("user_id")
            let genresColumn = Expression<String>("genres")
            let actorsColumn = Expression<String>("actors")
            let directorsColumn = Expression<String>("directors")
            let moviesColumn = Expression<String>("movies")

            let query = user_preferences.filter(user_id == userID)
            if let row = try db.pluck(query) {
                return (genres: row[genresColumn], actors: row[actorsColumn], directors: row[directorsColumn], movies: row[moviesColumn])
            } else {
                return nil
            }
        }
    
    // insets user prefences to the class
    func insertPreference(username: String, type: String, value: String) throws {
        let users = Table("users")
        let userId = Expression<Int64>("id")
        let usernameColumn = Expression<String>("username")

        let user_preferences = Table("user_preferences")
        let user_id = Expression<Int64>("user_id")
        let genresColumn = Expression<String>("genres")
        let actorsColumn = Expression<String>("actors")
        let directorsColumn = Expression<String>("directors")
        let moviesColumn = Expression<String>("movies")

        // Get the user ID from the users table.
        guard let userID = try db.pluck(users.filter(usernameColumn == username))?[userId] else {
            throw NSError(domain: "Error: User not found.", code: -1, userInfo: nil)
        }

        // Determine the appropriate column for the preference.
        let preferenceColumn: Expression<String>
        switch type {
        case "genre":
            preferenceColumn = genresColumn
        case "actor":
            preferenceColumn = actorsColumn
        case "director":
            preferenceColumn = directorsColumn
        case "movie":
            preferenceColumn = moviesColumn
        default:
            throw NSError(domain: "Error: Invalid preference type.", code: -1, userInfo: nil)
        }

        // Insert the new preference value into the database.
        let query = user_preferences.filter(user_id == userID)
        if let currentPreferences = try db.pluck(query)?[preferenceColumn] {
            let updatedPreferences = currentPreferences.isEmpty ? value : "\(currentPreferences), \(value)"
            try db.run(query.update(preferenceColumn <- updatedPreferences))
        } else {
            try insertUserPreferences(userID: userID, genres: type == "genre" ? value : "", actors: type == "actor" ? value : "", directors: type == "director" ? value : "", movies: type == "movie" ? value : "")
        }
    }

        //gets the users ID
    func getUserID(username: String) throws -> Int64? {
        let users = Table("users")
        let userId = Expression<Int64>("id")
        let usernameColumn = Expression<String>("username")

        let query = users.filter(usernameColumn == username)
        if let row = try db.pluck(query) {
            return row[userId]
        } else {
            return nil
        }
    }

    
}

// MARK: - Data model structs

//These structs define the data in our app (Movie, user, Recomendation, chatmessage) Each feild represents the field in the respective data model

struct Movie {
    let id: Int64
    let title: String
    let description: String
    let directorID: String
    let actorIDs: String
    let trailerURL: String
    let ratingsAndReviews: String
    let posterImageURL: String
}


struct User {
    let id: Int64
    let username: String
    let preferences: String
}

struct UserPreference {
    let userID: Int64
    let likedMovies: [Int]
    let wishlistMovies: [Int]
    let favoriteDirectors: [Int]
    let favoriteActors: [Int]
}

struct Recommendation {
    let id: Int64
    let userID: Int64
    let movieID: Int64
    let created_at: Date
}

struct ChatMessage {
    let id: Int64
    let userID: Int64
    let content: String
    let created_at: Date
    let role: String
}


