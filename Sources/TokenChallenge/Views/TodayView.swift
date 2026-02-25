import SwiftUI

struct TodayView: View {
    let store: TokenDataStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress ring
                ProgressRingView(
                    progress: store.progress,
                    goalMet: store.goalMet
                )
                .padding(.top, 12)

                // Token counter
                TokenCounterView(
                    current: store.todayTokens,
                    goal: store.settings.dailyGoal,
                    l10n: store.l10n
                )

                // Streak badge
                StreakBadgeView(streak: store.settings.streak, l10n: store.l10n)

                Divider()
                    .padding(.horizontal, 20)

                // Model breakdown
                modelBreakdown
            }
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var modelBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.l10n.byModel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            if let usage = store.todayUsage, !usage.byModel.isEmpty {
                let sorted = usage.byModel.sorted { $0.value > $1.value }
                ForEach(sorted, id: \.key) { model, tokens in
                    HStack {
                        Circle()
                            .fill(colorForModel(model))
                            .frame(width: 8, height: 8)
                        Text(shortModelName(model))
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text(store.l10n.formatCompact(tokens))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                Text(store.l10n.noDataYet)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func shortModelName(_ model: String) -> String {
        model
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20250929", with: "")
            .replacingOccurrences(of: "-20251001", with: "")
    }

    private func colorForModel(_ model: String) -> Color {
        if model.contains("opus") { return .purple }
        if model.contains("sonnet") { return .blue }
        if model.contains("haiku") { return .green }
        return .gray
    }

}
