import SwiftUI

struct TokenCounterView: View {
    let current: Int
    let goal: Int
    let l10n: L10n

    var body: some View {
        VStack(spacing: 4) {
            Text(l10n.formatFull(current))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.easeInOut, value: current)

            Text(l10n.tokens(goal))
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
