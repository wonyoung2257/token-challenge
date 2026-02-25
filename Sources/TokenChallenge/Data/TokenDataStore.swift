import Foundation
import Observation
import AppKit

@Observable
final class TokenDataStore {
    var settings: ChallengeSettings
    var todayUsage: DailyUsage?
    var recentDays: [DailyUsage] = [] // last 14 days
    var allRecords: [TokenRecord] = []

    var todayTokens: Int { todayUsage?.totalTokens ?? 0 }
    var progress: Double {
        guard settings.dailyGoal > 0 else { return 0 }
        return min(Double(todayTokens) / Double(settings.dailyGoal), 1.0)
    }
    var goalMet: Bool { todayTokens >= settings.dailyGoal }
    var progressPercent: Int { Int(progress * 100) }
    var l10n: L10n { L10n(lang: settings.language) }

    private let parser = JSONLParser()
    private var pollTimer: Timer?

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
        self.allRecords = records
        aggregateData(from: records)
        updateStreak()
    }

    func updateSettings(_ newSettings: ChallengeSettings) {
        settings = newSettings
        PersistenceManager.saveSettings(settings)
        if !allRecords.isEmpty {
            aggregateData(from: allRecords)
            updateStreak()
        }
    }

    // MARK: - Aggregation

    private func aggregateData(from records: [TokenRecord]) {
        let calendar = Calendar(identifier: .gregorian)
        let resetHour = settings.resetHourUTC

        // Group records by logical day
        var dailyMap: [String: DailyUsage] = [:]

        for record in records {
            let logicalDay = Self.logicalDay(for: record.timestamp, resetHourUTC: resetHour, calendar: calendar)
            let dayKey = Self.dayKey(for: logicalDay, calendar: calendar)

            if dailyMap[dayKey] == nil {
                let dayStart = calendar.startOfDay(for: logicalDay)
                dailyMap[dayKey] = DailyUsage(
                    id: dayKey,
                    date: dayStart,
                    totalTokens: 0,
                    byModel: [:],
                    byHour: [:],
                    records: []
                )
            }

            dailyMap[dayKey]!.totalTokens += record.totalTokens
            dailyMap[dayKey]!.byModel[record.model, default: 0] += record.totalTokens

            let hour = calendar.component(.hour, from: record.timestamp)
            dailyMap[dayKey]!.byHour[hour, default: 0] += record.totalTokens
            dailyMap[dayKey]!.records.append(record)
        }

        // Today
        let now = Date()
        let todayLogical = Self.logicalDay(for: now, resetHourUTC: resetHour, calendar: calendar)
        let todayKey = Self.dayKey(for: todayLogical, calendar: calendar)
        todayUsage = dailyMap[todayKey]

        // Recent 14 days
        let sorted = dailyMap.values.sorted { $0.date > $1.date }
        recentDays = Array(sorted.prefix(14))
    }

    // MARK: - Streak

    private func updateStreak() {
        let calendar = Calendar(identifier: .gregorian)
        let resetHour = settings.resetHourUTC
        let now = Date()
        let todayLogical = Self.logicalDay(for: now, resetHourUTC: resetHour, calendar: calendar)
        let todayKey = Self.dayKey(for: todayLogical, calendar: calendar)

        let currentGoalMet = (todayUsage?.totalTokens ?? 0) >= settings.dailyGoal

        if currentGoalMet {
            if let lastDate = settings.lastGoalMetDate {
                if lastDate == todayKey {
                    // Already recorded today
                } else {
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: todayLogical)!
                    let yesterdayKey = Self.dayKey(for: yesterday, calendar: calendar)
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
            // Check if streak should reset (last met > 1 day ago)
            if let lastDate = settings.lastGoalMetDate {
                let yesterday = calendar.date(byAdding: .day, value: -1, to: todayLogical)!
                let yesterdayKey = Self.dayKey(for: yesterday, calendar: calendar)
                if lastDate != todayKey && lastDate != yesterdayKey {
                    settings.streak = 0
                    PersistenceManager.saveSettings(settings)
                }
            }
        }
    }

    // MARK: - Day Boundary Helpers

    static func logicalDay(for date: Date, resetHourUTC: Int, calendar: Calendar) -> Date {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!

        let utcHour = utcCalendar.component(.hour, from: date)
        let shifted = utcHour < resetHourUTC
            ? utcCalendar.date(byAdding: .day, value: -1, to: date)!
            : date

        return utcCalendar.startOfDay(for: shifted)
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let y = utcCalendar.component(.year, from: date)
        let m = utcCalendar.component(.month, from: date)
        let d = utcCalendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
