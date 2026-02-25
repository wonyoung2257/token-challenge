import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let goalMet: Bool
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    goalMet ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Center content
            if goalMet {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(.green)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
