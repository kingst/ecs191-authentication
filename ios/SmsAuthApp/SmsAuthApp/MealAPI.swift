//
//  MealAPI.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/26/26.
//

import Foundation

// MARK: - API Response Models

struct UploadURLResponse: Decodable {
    let uploadUrl: String
    let imageId: String

    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case imageId = "image_id"
    }
}

struct FoodAnalysisResponse: Decodable {
    let calories: Int
    let carbohydratesGrams: Int
    let proteinGrams: Int
    let description: String
    let imageId: String
    let confidence: String

    enum CodingKeys: String, CodingKey {
        case calories
        case carbohydratesGrams = "carbohydrates_grams"
        case proteinGrams = "protein_grams"
        case description
        case imageId = "image_id"
        case confidence
    }
}

struct APIErrorResponse: Decodable {
    let error: String
}

// MARK: - MealAPI Errors

enum MealAPIError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case uploadFailed(String)
    case analysisFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .analysisFailed(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - MealAPI

struct MealAPI {
    static let shared = MealAPI()

    private static let baseURL = "https://ecs191-sms-authentication.uc.r.appspot.com"

    // Use ephemeral session on simulator to avoid QUIC protocol issues
    private static let urlSession: URLSession = {
        #if targetEnvironment(simulator)
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: config)
        #else
        return URLSession.shared
        #endif
    }()

    private init() {}

    // MARK: - API Methods

    func getSignedUploadURL(token: String) async throws -> UploadURLResponse {
        guard let url = URL(string: "\(Self.baseURL)/v1/food/upload_url") else {
            throw MealAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await Self.urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MealAPIError.uploadFailed("Invalid response")
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(UploadURLResponse.self, from: data)
        } else if httpResponse.statusCode == 401 {
            throw MealAPIError.notAuthenticated
        } else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw MealAPIError.uploadFailed(errorResponse?.error ?? "Unknown error")
        }
    }

    func uploadImage(to uploadURL: String, imageData: Data) async throws {
        guard let url = URL(string: uploadURL) else {
            throw MealAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (_, response) = try await Self.urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MealAPIError.uploadFailed("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw MealAPIError.uploadFailed("Upload returned status \(httpResponse.statusCode)")
        }
    }

    func analyzeFood(imageId: String, token: String) async throws -> FoodAnalysisResponse {
        guard let url = URL(string: "\(Self.baseURL)/v1/food/analyze/\(imageId)") else {
            throw MealAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await Self.urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MealAPIError.analysisFailed("Invalid response")
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(FoodAnalysisResponse.self, from: data)
        } else if httpResponse.statusCode == 401 {
            throw MealAPIError.notAuthenticated
        } else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw MealAPIError.analysisFailed(errorResponse?.error ?? "Analysis failed")
        }
    }

    func analyzeFoodImage(imageData: Data, token: String) async throws -> (FoodAnalysisResponse, Data) {
        // Step 1: Get signed upload URL
        let uploadResponse = try await getSignedUploadURL(token: token)

        // Step 2: Upload image to signed URL
        try await uploadImage(to: uploadResponse.uploadUrl, imageData: imageData)

        // Step 3: Analyze the uploaded image
        let analysisResponse = try await analyzeFood(imageId: uploadResponse.imageId, token: token)

        return (analysisResponse, imageData)
    }
}
