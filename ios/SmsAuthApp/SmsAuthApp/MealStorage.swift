//
//  MealStorage.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/26/26.
//

import SwiftUI

// MARK: - Persistence Models

struct PersistedMeal: Codable {
    let mealID: UUID
    let imageFilename: String?
    let date: Date
    let description: String
    let caloriesInKcal: Int
    let carbohydratesInGrams: Int
    let proteinInGrams: Int
}

struct PersistedGoals: Codable {
    var calories: Int
    var carbohydrates: Int
    var protein: Int
}

// MARK: - MealStorage

actor MealStorage {
    static let shared = MealStorage()

    private static let mealsFilename = "meals.json"
    private static let goalsFilename = "goals.json"
    private static let imagesDirectoryName = "meal_images"
    private static let retentionDays = 7

    private var storedMeals: [Meal] = []
    private var storedGoals: DailyMealGoals = .default
    private var hasLoadedFromDisk = false

    private init() {}

    // MARK: - File Paths

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var mealsFileURL: URL {
        documentsDirectory.appendingPathComponent(mealsFilename)
    }

    private static var goalsFileURL: URL {
        documentsDirectory.appendingPathComponent(goalsFilename)
    }

    private static var imagesDirectoryURL: URL {
        documentsDirectory.appendingPathComponent(imagesDirectoryName)
    }

    // MARK: - Initialization

    private func ensureImagesDirectoryExists() {
        let fileManager = FileManager.default
        let imagesDir = Self.imagesDirectoryURL
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }
    }

    private func loadFromDiskIfNeeded() {
        guard !hasLoadedFromDisk else { return }
        hasLoadedFromDisk = true

        ensureImagesDirectoryExists()
        loadMealsFromDisk()
        loadGoalsFromDisk()
        pruneOldMeals()
    }

    // MARK: - Meals Persistence

    private func loadMealsFromDisk() {
        let fileURL = Self.mealsFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let persistedMeals = try? JSONDecoder().decode([PersistedMeal].self, from: data) else {
            storedMeals = []
            return
        }

        storedMeals = persistedMeals.map { persisted in
            let (image, imageData) = loadImage(filename: persisted.imageFilename)
            return Meal(
                mealID: persisted.mealID,
                image: image,
                imageData: imageData,
                date: persisted.date,
                description: persisted.description,
                caloriesInKcal: persisted.caloriesInKcal,
                carbohydratesInGrams: persisted.carbohydratesInGrams,
                proteinInGrams: persisted.proteinInGrams
            )
        }
    }

    private func saveMealsToDisk() {
        let persistedMeals = storedMeals.map { meal in
            PersistedMeal(
                mealID: meal.mealID,
                imageFilename: imageFilename(for: meal.mealID),
                date: meal.date,
                description: meal.description,
                caloriesInKcal: meal.caloriesInKcal,
                carbohydratesInGrams: meal.carbohydratesInGrams,
                proteinInGrams: meal.proteinInGrams
            )
        }

        guard let data = try? JSONEncoder().encode(persistedMeals) else { return }
        try? data.write(to: Self.mealsFileURL)
    }

    // MARK: - Goals Persistence

    private func loadGoalsFromDisk() {
        let fileURL = Self.goalsFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let persistedGoals = try? JSONDecoder().decode(PersistedGoals.self, from: data) else {
            storedGoals = .default
            return
        }

        storedGoals = DailyMealGoals(
            calories: persistedGoals.calories,
            carbohydrates: persistedGoals.carbohydrates,
            protein: persistedGoals.protein
        )
    }

    private func saveGoalsToDisk() {
        let persistedGoals = PersistedGoals(
            calories: storedGoals.calories,
            carbohydrates: storedGoals.carbohydrates,
            protein: storedGoals.protein
        )

        guard let data = try? JSONEncoder().encode(persistedGoals) else { return }
        try? data.write(to: Self.goalsFileURL)
    }

    // MARK: - Image Persistence

    private func imageFilename(for mealID: UUID) -> String {
        "\(mealID.uuidString).jpg"
    }

    private func imageURL(for filename: String) -> URL {
        Self.imagesDirectoryURL.appendingPathComponent(filename)
    }

    private func saveImage(data: Data, for mealID: UUID) {
        ensureImagesDirectoryExists()
        let filename = imageFilename(for: mealID)
        let url = imageURL(for: filename)
        try? data.write(to: url)
    }

    private func loadImage(filename: String?) -> (Image?, Data?) {
        guard let filename = filename else { return (nil, nil) }
        let url = imageURL(for: filename)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return (nil, nil)
        }
        return (Image(uiImage: uiImage), data)
    }

    private func deleteImage(for mealID: UUID) {
        let filename = imageFilename(for: mealID)
        let url = imageURL(for: filename)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Pruning

    private func pruneOldMeals() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -Self.retentionDays, to: Date()) else {
            return
        }

        let mealsToDelete = storedMeals.filter { $0.date < cutoffDate }
        for meal in mealsToDelete {
            deleteImage(for: meal.mealID)
        }

        let originalCount = storedMeals.count
        storedMeals = storedMeals.filter { $0.date >= cutoffDate }

        if storedMeals.count != originalCount {
            saveMealsToDisk()
        }
    }

    // MARK: - Public Interface

    func add(meal: Meal) {
        loadFromDiskIfNeeded()

        if let imageData = meal.imageData {
            saveImage(data: imageData, for: meal.mealID)
        }

        storedMeals.insert(meal, at: 0)
        saveMealsToDisk()
        pruneOldMeals()
    }

    func queryMeals() -> [Meal] {
        loadFromDiskIfNeeded()
        return storedMeals
    }

    func update(meal: Meal) {
        loadFromDiskIfNeeded()

        if let index = storedMeals.firstIndex(where: { $0.mealID == meal.mealID }) {
            if let imageData = meal.imageData {
                saveImage(data: imageData, for: meal.mealID)
            }
            storedMeals[index] = meal
            saveMealsToDisk()
        }
    }

    func delete(meal: Meal) {
        loadFromDiskIfNeeded()

        deleteImage(for: meal.mealID)
        storedMeals.removeAll { $0.mealID == meal.mealID }
        saveMealsToDisk()
    }

    func goals() -> DailyMealGoals {
        loadFromDiskIfNeeded()
        return storedGoals
    }

    func update(goals: DailyMealGoals) {
        loadFromDiskIfNeeded()
        storedGoals = goals
        saveGoalsToDisk()
    }
}
