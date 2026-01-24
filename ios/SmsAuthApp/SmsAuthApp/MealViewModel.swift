//
//  MealViewModel.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/23/26.
//

import SwiftUI

// MARK: - Pending Meal (for confirmation flow)

struct PendingMeal {
    let imageData: Data
    let image: Image
    var description: String
    var calories: Int
    var carbohydrates: Int
    var protein: Int
    let confidence: String
}

// MARK: - MealViewModel

@MainActor
class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var goals: DailyMealGoals = .default

    // Analysis state
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var pendingMeal: PendingMeal?

    private let mealService = MealService.shared

    init() {
        loadData()
    }

    func loadData() {
        meals = mealService.queryMeals()
        goals = mealService.goals()
    }

    var todaysMeals: [Meal] {
        let calendar = Calendar.current
        return meals.filter { calendar.isDateInToday($0.date) }
    }

    var totalCaloriesConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.caloriesInKcal }
    }

    var totalProteinConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.proteinInGrams }
    }

    var totalCarbsConsumed: Int {
        todaysMeals.reduce(0) { $0 + $1.carbohydratesInGrams }
    }

    var caloriesRemaining: Int {
        max(0, goals.calories - totalCaloriesConsumed)
    }

    // MARK: - Analysis Flow

    func analyzeImage(_ imageData: Data, token: String) async {
        isAnalyzing = true
        analysisError = nil

        do {
            let (response, data) = try await mealService.analyzeFoodImage(imageData: imageData, token: token)

            // Create SwiftUI Image from data
            guard let uiImage = UIImage(data: data) else {
                analysisError = "Failed to process image"
                isAnalyzing = false
                return
            }

            pendingMeal = PendingMeal(
                imageData: data,
                image: Image(uiImage: uiImage),
                description: response.description,
                calories: response.calories,
                carbohydrates: response.carbohydratesGrams,
                protein: response.proteinGrams,
                confidence: response.confidence
            )
        } catch {
            analysisError = error.localizedDescription
        }

        isAnalyzing = false
    }

    func confirmMeal() {
        guard let pending = pendingMeal else { return }

        let meal = Meal(
            mealID: UUID(),
            image: pending.image,
            imageData: pending.imageData,
            date: Date(),
            description: pending.description,
            caloriesInKcal: pending.calories,
            carbohydratesInGrams: pending.carbohydrates,
            proteinInGrams: pending.protein
        )

        mealService.add(meal: meal)
        loadData() // Refresh the published meals array
        pendingMeal = nil
    }

    func cancelPendingMeal() {
        pendingMeal = nil
        analysisError = nil
    }

    func clearError() {
        analysisError = nil
    }
}
