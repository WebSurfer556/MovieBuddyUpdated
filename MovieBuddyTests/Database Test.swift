//
//  Database Test.swift
//  MovieBuddyTests
//
//  Created by Nic Krystynak on 4/20/23.
//
@testable import MovieBuddy

import XCTest

final class Database_Test: XCTestCase {
    func testExtractPreferences() {
        let expectation = XCTestExpectation(description: "Extract preferences from user response")

        let apiManager = APIManager()
        let username = "testuser"
        let userResponse = "I love action and comedy movies. Some of my favorite actors are Tom Hanks and Meryl Streep. I enjoy watching movies directed by Christopher Nolan and Steven Spielberg. My favorite movies include Inception and The Matrix."

        apiManager.extractPreferences(username: username, userResponse: userResponse) { result in
            switch result {
            case .success(let extractedPreferences):
                XCTAssert(!extractedPreferences.isEmpty, "Extracted preferences should not be empty")
                print("Extracted preferences: \(extractedPreferences)")
            case .failure(let error):
                XCTFail("Error extracting preferences: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }

    func testProcessPreferences() {
        let dbManager = DatabaseManager()
        let sessionManager = SessionManager()
        let username = "testuser"
        let testUserID: Int64 = Int64("some_username") ?? 0
        let aiResponse = "Genres: Action, Comedy; Actors: Tom Hanks, Meryl Streep; Directors: Christopher Nolan, Steven Spielberg; Movies: Inception, The Matrix."

        do {
            try sessionManager.processPreferences(username: username, aiResponse: aiResponse)
            XCTAssertNoThrow(try dbManager?.updateUserPreferences(userID: testUserID, genres: "Action, Comedy", actors: "Tom Hanks, Meryl Streep", directors: "Christopher Nolan, Steven Spielberg", movies: "Inception, The Matrix"))
        } catch {
            XCTFail("Error processing preferences: \(error.localizedDescription)")
        }
    }

    
    func testDatabaseFunctions() {
        let dbManager = DatabaseManager()
        

        
        // Replace 'yourUserID' with a valid user ID from your users table
        let testUserID: Int64 = Int64("some_username") ?? 0
        
        // Test insertUserPreferences
        XCTAssertNoThrow(try dbManager?.insertUserPreferences(userID: testUserID, genres: "Action, Comedy", actors: "Tom Hanks", directors: "Christopher Nolan", movies: "Inception"))
        
        // Test updateUserPreferences
        XCTAssertNoThrow(try dbManager?.updateUserPreferences(userID: testUserID, genres: "Action, Comedy, Sci-Fi", actors: "Tom Hanks, Meryl Streep", directors: "Christopher Nolan, Steven Spielberg", movies: "Inception, The Matrix"))
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // Call your testDatabaseFunctions() function here
        testDatabaseFunctions()
        testExtractPreferences()
        testProcessPreferences()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
