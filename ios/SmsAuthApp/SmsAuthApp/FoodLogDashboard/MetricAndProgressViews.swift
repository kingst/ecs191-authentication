//
//  MetricAndProgressViews.swift
//  SmsAuthApp
//
//  Created by Sam King on 1/23/26.
//
import SwiftUI

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
