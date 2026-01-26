//
//  MealService.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/23/26.
//

import SwiftUI

// MARK: - Models

struct Meal: Identifiable {
    let mealID: UUID
    let image: Image?
    let imageData: Data?
    let date: Date
    let description: String
    let caloriesInKcal: Int
    let carbohydratesInGrams: Int
    let proteinInGrams: Int

    var id: UUID { mealID }
}

struct DailyMealGoals {
    var calories: Int
    var carbohydrates: Int
    var protein: Int

    static let `default` = DailyMealGoals(
        calories: 2000,
        carbohydrates: 150,
        protein: 100
    )
}

// MARK: - MealService

actor MealService {
    static let shared = MealService()

    private let storage = MealStorage.shared
    private let api = MealAPI.shared

    private init() {}

    // MARK: - API Methods

    func analyzeFoodImage(imageData: Data, token: String) async throws -> (FoodAnalysisResponse, Data) {
        try await api.analyzeFoodImage(imageData: imageData, token: token)
    }

    // MARK: - Storage Methods

    func add(meal: Meal) async {
        await storage.add(meal: meal)
    }

    func queryMeals() async -> [Meal] {
        await storage.queryMeals()
    }

    func update(meal: Meal) async {
        await storage.update(meal: meal)
    }

    func delete(meal: Meal) async {
        await storage.delete(meal: meal)
    }

    func goals() async -> DailyMealGoals {
        await storage.goals()
    }

    func update(goals: DailyMealGoals) async {
        await storage.update(goals: goals)
    }
}
