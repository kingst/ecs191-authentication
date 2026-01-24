//
//  HomeView.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/13/26.
//

import SwiftUI
import UIKit

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageCaptured: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                parent.onImageCaptured(imageData)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Food Analysis Sheet

struct FoodAnalysisSheet: View {
    @ObservedObject var mealViewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if mealViewModel.isAnalyzing {
                    analyzingView
                } else if let pending = mealViewModel.pendingMeal {
                    confirmationView(pending: pending)
                } else if let error = mealViewModel.analysisError {
                    errorView(error: error)
                } else {
                    // Shouldn't happen, but handle gracefully
                    Text("No analysis in progress")
                }
            }
            .navigationTitle("Food Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        mealViewModel.cancelPendingMeal()
                        dismiss()
                    }
                }
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your food...")
                .font(.headline)
            Text("This may take a moment")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func confirmationView(pending: PendingMeal) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food image
                pending.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .padding(.horizontal)

                // Confidence indicator
                HStack {
                    Image(systemName: confidenceIcon(pending.confidence))
                        .foregroundColor(confidenceColor(pending.confidence))
                    Text("\(pending.confidence.capitalized) confidence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Editable fields
                VStack(alignment: .leading, spacing: 16) {
                    Text("Description")
                        .font(.headline)
                    TextField("Food description", text: Binding(
                        get: { mealViewModel.pendingMeal?.description ?? "" },
                        set: { mealViewModel.pendingMeal?.description = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Divider()

                    // Nutrition info
                    Text("Nutrition")
                        .font(.headline)

                    nutritionRow(
                        label: "Calories",
                        value: Binding(
                            get: { mealViewModel.pendingMeal?.calories ?? 0 },
                            set: { mealViewModel.pendingMeal?.calories = $0 }
                        ),
                        unit: "kcal"
                    )

                    nutritionRow(
                        label: "Protein",
                        value: Binding(
                            get: { mealViewModel.pendingMeal?.protein ?? 0 },
                            set: { mealViewModel.pendingMeal?.protein = $0 }
                        ),
                        unit: "g"
                    )

                    nutritionRow(
                        label: "Carbohydrates",
                        value: Binding(
                            get: { mealViewModel.pendingMeal?.carbohydrates ?? 0 },
                            set: { mealViewModel.pendingMeal?.carbohydrates = $0 }
                        ),
                        unit: "g"
                    )
                }
                .padding(.horizontal)

                // Confirm button
                Button {
                    mealViewModel.confirmMeal()
                    dismiss()
                } label: {
                    Text("Add to Log")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
        }
    }

    private func nutritionRow(label: String, value: Binding<Int>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
            Text(unit)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }

    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Analysis Failed")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                mealViewModel.clearError()
                dismiss()
            }
            .padding(.top)
        }
    }

    private func confidenceIcon(_ confidence: String) -> String {
        switch confidence.lowercased() {
        case "high": return "checkmark.circle.fill"
        case "medium": return "checkmark.circle"
        default: return "questionmark.circle"
        }
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return .green
        case "medium": return .orange
        default: return .gray
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Metric Views

struct CaloriesMetricView: View {
    let remaining: Int
    let goal: Int

    private var progress: Double {
        // Inverse progress - shows remaining
        let consumed = goal - remaining
        return max(0, min(1, Double(consumed) / Double(goal)))
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue, Color.cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                CircularProgressView(
                    progress: progress,
                    lineWidth: 12,
                    gradient: gradient
                )
                .frame(width: 120, height: 120)

                VStack(spacing: 2) {
                    Text("\(remaining)")
                        .font(.system(size: 28, weight: .bold))
                    Text("kcal left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("of \(goal) goal")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MacroMetricView: View {
    let current: Int
    let target: Int
    let label: String
    let gradient: LinearGradient

    private var progress: Double {
        max(0, min(1, Double(current) / Double(target)))
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                CircularProgressView(
                    progress: progress,
                    lineWidth: 8,
                    gradient: gradient
                )
                .frame(width: 70, height: 70)

                VStack(spacing: 0) {
                    Text("\(current)g")
                        .font(.system(size: 14, weight: .bold))
                }
            }

            Text("\(current)g / \(target)g")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Meal Card

struct MealCard: View {
    let meal: Meal

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private var mealType: String {
        let hour = Calendar.current.component(.hour, from: meal.date)
        switch hour {
        case 5..<11: return "Breakfast"
        case 11..<14: return "Lunch"
        case 14..<17: return "Snack"
        default: return "Dinner"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                if let image = meal.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                // Meal type and time
                Text("\(mealType) • \(timeFormatter.string(from: meal.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Food description
                Text(meal.description)
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Nutritional breakdown
                Text("\(meal.caloriesInKcal) cal | \(meal.proteinInGrams)g P | \(meal.carbohydratesInGrams)g C")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Tab Enum

enum HomeTab {
    case dashboard
    case profile
}

// MARK: - Home View

struct HomeView: View {
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
    HomeView(userService: UserService())
}
