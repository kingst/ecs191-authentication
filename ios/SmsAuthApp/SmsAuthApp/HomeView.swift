//
//  HomeView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var userService: UserService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("You're logged in!")
                .font(.title)
                .fontWeight(.bold)

            if let userId = userService.userId {
                Text("User ID: \(userId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                userService.logout()
            } label: {
                Text("Log out")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    HomeView(userService: UserService())
}
