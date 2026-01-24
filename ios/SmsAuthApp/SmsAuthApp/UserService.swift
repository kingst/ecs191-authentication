//
//  UserService.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import Foundation

@MainActor
class UserService: ObservableObject {
    private static let baseURL = "https://ecs191-sms-authentication.uc.r.appspot.com"
    private static let appId = "com.smsauthapp.ios"

    // Use ephemeral session on simulator to avoid QUIC protocol issues with App Engine
    private static let urlSession: URLSession = {
        #if targetEnvironment(simulator)
        let config = URLSessionConfiguration.ephemeral
        
        // FORCE HTTP/1.1
        // This prevents HTTP/2 and HTTP/3 upgrades entirely.
        // It is slower, but rock-solid stable for the Simulator.
        config.httpMaximumConnectionsPerHost = 1
        
        return URLSession(configuration: config)
        #else
        return URLSession.shared
        #endif
    }()

    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true
    @Published var userId: String?
    @Published var authError: String?
    @Published var isLoading = false

    // Store the phone number between views
    var phoneNumber: String = ""

    private(set) var token: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    init() {
        Task {
            await checkAuthentication()
        }
    }

    func clearAuthError() {
        authError = nil
    }

    func sendVerificationCode(phoneNumber: String) async {
        self.phoneNumber = phoneNumber
        isLoading = true
        authError = nil

        defer { isLoading = false }

        guard let url = URL(string: "\(Self.baseURL)/v1/send_sms_code") else {
            authError = "Invalid URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "phone_number": phoneNumber,
            "app_id": Self.appId
        ]

        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await Self.urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                authError = "Invalid response"
                return
            }

            if httpResponse.statusCode == 200 {
                // Success - navigation will be handled by the view
                return
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                authError = errorResponse?.error ?? "Failed to send verification code"
            }
        } catch {
            authError = "Network error: \(error.localizedDescription)"
        }
    }

    func verifyCode(_ code: String) async -> Bool {
        isLoading = true
        authError = nil

        defer { isLoading = false }

        guard let url = URL(string: "\(Self.baseURL)/v1/verify_code") else {
            authError = "Invalid URL"
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "phone_number": phoneNumber,
            "app_id": Self.appId,
            "code": code
        ]

        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await Self.urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                authError = "Invalid response"
                return false
            }

            if httpResponse.statusCode == 200 {
                let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)
                token = verifyResponse.token
                userId = verifyResponse.userId
                isAuthenticated = true
                return true
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                authError = errorResponse?.error ?? "Failed to verify code"
                return false
            }
        } catch {
            authError = "Network error: \(error.localizedDescription)"
            return false
        }
    }

    func logout() {
        token = nil
        userId = nil
        isAuthenticated = false
        phoneNumber = ""
    }

    private func checkAuthentication() async {
        defer { isCheckingAuth = false }

        guard let token = token else {
            isAuthenticated = false
            return
        }

        guard let url = URL(string: "\(Self.baseURL)/v1/user") else {
            isAuthenticated = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await Self.urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                isAuthenticated = false
                return
            }

            if httpResponse.statusCode == 200 {
                let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
                userId = userResponse.userId
                isAuthenticated = true
            } else {
                // Token is invalid, clear it
                self.token = nil
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
    }
}

// MARK: - Response Models

private struct ErrorResponse: Decodable {
    let error: String
}

private struct VerifyResponse: Decodable {
    let success: Bool
    let token: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case success
        case token
        case userId = "user_id"
    }
}

private struct UserResponse: Decodable {
    let userId: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
