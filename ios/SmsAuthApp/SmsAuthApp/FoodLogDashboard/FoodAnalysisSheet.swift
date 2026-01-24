import SwiftUI

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
