//
//  VerifyCodeView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI

struct VerifyCodeView: View {
    @ObservedObject var userService: UserService

    @State private var code = ""
    @FocusState private var isCodeFieldFocused: Bool

    private let codeLength = 6

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter the code to verify your phone")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Code entry field
            TextField("000000", text: $code)
                .keyboardType(.numberPad)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 48)
                .focused($isCodeFieldFocused)
                .onChange(of: code) { _, newValue in
                    // Only allow digits
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        code = filtered
                    }

                    // Limit to 6 digits
                    if code.count > codeLength {
                        code = String(code.prefix(codeLength))
                    }

                    // Clear error when editing
                    userService.clearAuthError()

                    // Auto-advance when 6 digits entered
                    if code.count == codeLength {
                        Task {
                            await userService.verifyCode(code)
                        }
                    }
                }

            // Error text
            if let error = userService.authError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            // Loading indicator
            if userService.isLoading {
                ProgressView()
                    .padding()
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }
}

#Preview {
    VerifyCodeView(userService: UserService())
}
