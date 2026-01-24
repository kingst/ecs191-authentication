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
    @State private var isSubmitting = false
    @FocusState private var isCodeFieldFocused: Bool

    private let codeLength = 6

    private var sanitizedCode: String {
        String(code.filter { $0.isNumber }.prefix(codeLength))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter the code to verify your phone")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Code entry field
            TextField("", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 48)
                .focused($isCodeFieldFocused)
                .onChange(of: code) { _, newValue in
                    // Clear error when editing
                    userService.clearAuthError()

                    // Sanitize input (allow autofill to complete first)
                    let sanitized = String(newValue.filter { $0.isNumber }.prefix(codeLength))
                    if sanitized != newValue {
                        code = sanitized
                        return
                    }

                    // Auto-submit when 6 digits entered
                    if sanitized.count == codeLength && !isSubmitting {
                        isSubmitting = true
                        Task {
                            await userService.verifyCode(sanitized)
                            isSubmitting = false
                        }
                    }
                }

            // Show entered code as placeholder hint
            Text("Enter 6-digit code")
                .font(.footnote)
                .foregroundColor(.secondary)

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
            // Delay focus slightly to allow autofill to register
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFieldFocused = true
            }
        }
    }
}

#Preview {
    VerifyCodeView(userService: UserService())
}
