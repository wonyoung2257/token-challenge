import Foundation
import Observation
import AppKit

@Observable
final class TokenDataStore {
    var settings: ChallengeSettings
    var todayUsage: DailyUsage?
    var recentDays: [DailyUsage] = [] // last 14 days

    var todayTokens: Int { todayUsage?.totalTokens ?? 0 }
    var progress: Double {
        guard settings.dailyGoal > 0 else { return 0 }
        return min(Double(todayTokens) / Double(settings.dailyGoal), 1.0)
    }
    var goalMet: Bool { todayTokens >= settings.dailyGoal }
    var progressPercent: Int { Int(progress * 100) }
    var l10n: L10n { L10n(lang: settings.language) }

    /// Called by AppDelegate after each refresh to update menu bar
    var onDataChanged: (() -> Void)?

    private let parser = JSONLParser()
    private var pollTimer: Timer?

    // Shared UTC calendar — avoid re-creating per record
    private static let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    init() {
        self.settings = PersistenceManager.loadSettings()
    }

    func startPolling() {
        Task { await refresh() }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    @MainActor
    func refresh() async {
        let records = await parser.parseAllRecords()
        aggregateData(from: records)
        updateStreak()
        onDataChanged?()
    }

    func updateSettings(_ newSettings: ChallengeSettings) {
        let old = settings
        settings = newSettings
        PersistenceManager.saveSettings(settings)
        if newSettings.dailyGoal != old.dailyGoal || newSettings.resetHourUTC != old.resetHourUTC || newSettings.language != old.language {
            Task { await refresh() }
        }
    }

    // MARK: - Aggregation

    private func aggregateData(from records: [TokenRecord]) {
        let utcCal = Self.utcCalendar
        let resetHour = settings.resetHourUTC

        // Only process records from the last 15 days (14 days + today buffer)
        let cutoff = utcCal.date(byAdding: .day, value: -15, to: Date())!

        var dailyMap: [String: DailyUsage] = [:]

        for record in records {
            guard record.timestamp >= cutoff else { continue }

            let logicalDay = Self.logicalDay(for: record.timestamp, resetHourUTC: resetHour, utcCalendar: utcCal)
            let dayKey = Self.dayKey(for: logicalDay, utcCalendar: utcCal)

            if dailyMap[dayKey] == nil {
                let dayStart = utcCal.startOfDay(for: logicalDay)
                dailyMap[dayKey] = DailyUsage(
                    id: dayKey,
                    date: dayStart,
                    totalTokens: 0,
                    byModel: [:],
                    byHour: [:]
                )
            }

            dailyMap[dayKey]!.totalTokens += record.totalTokens
            dailyMap[dayKey]!.byModel[record.model, default: 0] += record.totalTokens

            let hour = utcCal.component(.hour, from: record.timestamp)
            dailyMap[dayKey]!.byHour[hour, default: 0] += record.totalTokens
        }

        // Today
        let now = Date()
        let todayLogical = Self.logicalDay(for: now, resetHourUTC: resetHour, utcCalendar: utcCal)
        let todayKey = Self.dayKey(for: todayLogical, utcCalendar: utcCal)
        todayUsage = dailyMap[todayKey]

        // Recent 14 days
        let sorted = dailyMap.values.sorted { $0.date > $1.date }
        recentDays = Array(sorted.prefix(14))
    }

    // MARK: - Streak

    private func updateStreak() {
        let utcCal = Self.utcCalendar
        let resetHour = settings.resetHourUTC
        let now = Date()
        let todayLogical = Self.logicalDay(for: now, resetHourUTC: resetHour, utcCalendar: utcCal)
        let todayKey = Self.dayKey(for: todayLogical, utcCalendar: utcCal)

        let currentGoalMet = (todayUsage?.totalTokens ?? 0) >= settings.dailyGoal

        if currentGoalMet {
            if let lastDate = settings.lastGoalMetDate {
                if lastDate == todayKey {
                    // Already recorded today
                } else {
                    let yesterday = utcCal.date(byAdding: .day, value: -1, to: todayLogical)!
                    let yesterdayKey = Self.dayKey(for: yesterday, utcCalendar: utcCal)
                    if lastDate == yesterdayKey {
                        settings.streak += 1
                    } else {
                        settings.streak = 1
                    }
                    settings.lastGoalMetDate = todayKey
                }
            } else {
                settings.streak = 1
                settings.lastGoalMetDate = todayKey
            }
            PersistenceManager.saveSettings(settings)
        } else {
            if let lastDate = settings.lastGoalMetDate {
                let yesterday = utcCal.date(byAdding: .day, value: -1, to: todayLogical)!
                let yesterdayKey = Self.dayKey(for: yesterday, utcCalendar: utcCal)
                if lastDate != todayKey && lastDate != yesterdayKey {
                    settings.streak = 0
                    PersistenceManager.saveSettings(settings)
                }
            }
        }
    }

    // MARK: - Day Boundary Helpers

    static func logicalDay(for date: Date, resetHourUTC: Int, utcCalendar: Calendar) -> Date {
        let utcHour = utcCalendar.component(.hour, from: date)
        let shifted = utcHour < resetHourUTC
            ? utcCalendar.date(byAdding: .day, value: -1, to: date)!
            : date

        return utcCalendar.startOfDay(for: shifted)
    }

    static func dayKey(for date: Date, utcCalendar: Calendar) -> String {
        let y = utcCalendar.component(.year, from: date)
        let m = utcCalendar.component(.month, from: date)
        let d = utcCalendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
