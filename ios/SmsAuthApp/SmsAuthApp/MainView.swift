//
//  MainView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI

struct MainView: View {
    @StateObject private var userService = UserService()
    @State private var showVerifyCode = false

    var body: some View {
        Group {
            if userService.isCheckingAuth {
                ProgressView()
            } else if userService.isAuthenticated {
                FoodLogDashboard(userService: userService)
            } else if showVerifyCode {
                VerifyCodeView(userService: userService)
            } else {
                EnterPhoneNumberView(
                    userService: userService,
                    showVerifyCode: $showVerifyCode
                )
            }
        }
        .animation(.easeInOut, value: userService.isAuthenticated)
        .animation(.easeInOut, value: showVerifyCode)
        .onChange(of: userService.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                showVerifyCode = false
            }
        }
    }
}

#Preview {
    MainView()
}
