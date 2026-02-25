import SwiftUI

struct StreakBadgeView: View {
    let streak: Int
    var l10n: L10n = L10n(lang: .en)

    var body: some View {
        if streak > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(l10n.dayStreak(streak))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
}
