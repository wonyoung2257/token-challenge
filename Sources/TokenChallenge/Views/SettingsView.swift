import SwiftUI

struct SettingsView: View {
    let store: TokenDataStore
    @State private var selectedPreset: GoalPreset? = nil
    @State private var customGoal: String = ""
    @State private var resetHour: Int = 15
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Language
                languageSection

                Divider()
                    .padding(.horizontal, 20)

                // Daily Goal
                goalSection

                Divider()
                    .padding(.horizontal, 20)

                // Timezone / Reset Hour
                timezoneSection

                Divider()
                    .padding(.horizontal, 20)

                // Streak
                streakSection
            }
            .padding(.vertical, 12)
        }
        .onAppear {
            resetHour = store.settings.resetHourUTC
            customGoal = "\(store.settings.dailyGoal)"
            selectedPreset = GoalPreset(rawValue: store.settings.dailyGoal)
        }
    }

    // MARK: - Language Section

    @ViewBuilder
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.l10n.language)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)

            Picker("", selection: Binding(
                get: { store.settings.language },
                set: { newLang in
                    var settings = store.settings
                    settings.language = newLang
                    store.updateSettings(settings)
                }
            )) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Goal Section

    @ViewBuilder
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.l10n.dailyGoal)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)

            // Presets
            HStack(spacing: 8) {
                ForEach(GoalPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        customGoal = "\(preset.rawValue)"
                        applyGoal(preset.rawValue)
                    } label: {
                        Text(store.l10n.formatPreset(preset.rawValue))
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedPreset == preset ? .accentColor : .secondary)
                }
            }
            .padding(.horizontal, 20)

            // Custom input
            HStack {
                TextField(store.l10n.customGoal, text: $customGoal)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit {
                        if let value = Int(customGoal.replacingOccurrences(of: ",", with: "")), value > 0 {
                            selectedPreset = GoalPreset(rawValue: value)
                            applyGoal(value)
                        }
                    }
                Text(store.l10n.tokensUnit)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Timezone Section

    @ViewBuilder
    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.l10n.dayResetTime)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)

            HStack {
                Picker("", selection: $resetHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d:00 UTC", hour)).tag(hour)
                    }
                }
                .frame(width: 140)
                .onChange(of: resetHour) { _, newValue in
                    var settings = store.settings
                    settings.resetHourUTC = newValue
                    store.updateSettings(settings)
                }

                Spacer()

                Text(localTimeLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Streak Section

    @ViewBuilder
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.l10n.streak)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)

            HStack {
                StreakBadgeView(streak: store.settings.streak, l10n: store.l10n)
                Spacer()
                Button(store.l10n.resetStreak) {
                    showResetAlert = true
                }
                .font(.system(size: 12))
                .foregroundStyle(.red)
            }
            .padding(.horizontal, 20)

            // Quit button
            Divider()
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text(store.l10n.quitApp)
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .alert(store.l10n.resetStreakQuestion, isPresented: $showResetAlert) {
            Button(store.l10n.cancel, role: .cancel) {}
            Button(store.l10n.reset, role: .destructive) {
                var settings = store.settings
                settings.streak = 0
                settings.lastGoalMetDate = nil
                store.updateSettings(settings)
            }
        } message: {
            Text(store.l10n.resetStreakMessage)
        }
    }

    // MARK: - Helpers

    private func applyGoal(_ value: Int) {
        var settings = store.settings
        settings.dailyGoal = value
        store.updateSettings(settings)
    }

    private var localTimeLabel: String {
        let tz = TimeZone.current
        let offsetSeconds = tz.secondsFromGMT()
        let localHour = (resetHour * 3600 + offsetSeconds) / 3600
        let adjusted = ((localHour % 24) + 24) % 24
        return store.l10n.localTimeEq(adjusted)
    }
}
