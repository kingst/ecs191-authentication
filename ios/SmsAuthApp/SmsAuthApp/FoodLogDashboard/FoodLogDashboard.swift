//
//  HomeView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI

// MARK: - Tab Enum

enum HomeTab {
    case dashboard
    case profile
}

// MARK: - Home View

struct FoodLogDashboard: View {
    @ObservedObject var userService: UserService
    @StateObject private var mealViewModel = MealViewModel()
    @State private var selectedTab: HomeTab = .dashboard
    @State private var showingCamera = false
    @State private var showingAnalysisSheet = false

    private var proteinGradient: LinearGradient {
        LinearGradient(
            colors: [Color.purple, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var carbsGradient: LinearGradient {
        LinearGradient(
            colors: [Color.orange, Color.yellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            if selectedTab == .dashboard {
                dashboardContent
            } else {
                profileContent
            }

            // Bottom tab bar
            bottomTabBar
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker { imageData in
                guard let token = userService.token else { return }
                showingAnalysisSheet = true
                Task {
                    await mealViewModel.analyzeImage(imageData, token: token)
                }
            }
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            FoodAnalysisSheet(mealViewModel: mealViewModel)
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Section - Daily Metrics
                metricsSection
                    .padding(.top, 20)

                // Middle Section - Today's Log
                todaysLogSection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var metricsSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Protein (Left)
            MacroMetricView(
                current: mealViewModel.totalProteinConsumed,
                target: mealViewModel.goals.protein,
                label: "Protein",
                gradient: proteinGradient
            )

            Spacer()

            // Calories (Center, largest)
            CaloriesMetricView(
                remaining: mealViewModel.caloriesRemaining,
                goal: mealViewModel.goals.calories
            )

            Spacer()

            // Carbs (Right)
            MacroMetricView(
                current: mealViewModel.totalCarbsConsumed,
                target: mealViewModel.goals.carbohydrates,
                label: "Carbs",
                gradient: carbsGradient
            )
        }
        .padding(.horizontal, 8)
    }

    private var todaysLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Log")
                .font(.headline)

            if mealViewModel.todaysMeals.isEmpty {
                Text("No meals logged today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(mealViewModel.todaysMeals) { meal in
                    MealCard(meal: meal)
                }
            }
        }
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

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

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack {
            // Dashboard tab
            Button {
                selectedTab = .dashboard
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                    Text("Dashboard")
                        .font(.caption2)
                }
                .foregroundColor(selectedTab == .dashboard ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)

            // Camera button (prominent)
            Button {
                showingCamera = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 56, height: 56)
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10)

            // Profile tab
            Button {
                selectedTab = .profile
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.title2)
                    Text("Profile")
                        .font(.caption2)
                }
                .foregroundColor(selectedTab == .profile ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

#Preview {
    FoodLogDashboard(userService: UserService())
}
