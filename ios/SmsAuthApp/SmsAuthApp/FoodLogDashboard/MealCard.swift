//
//  MealCard.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/23/26.
//
import SwiftUI

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
