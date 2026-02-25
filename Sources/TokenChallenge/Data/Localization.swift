import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case en = "en"
    case ko = "ko"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .ko: return "한국어"
        }
    }
}

struct L10n {
    let lang: AppLanguage

    // MARK: - Tabs
    var tabToday: String { lang == .ko ? "오늘" : "Today" }
    var tabTrends: String { lang == .ko ? "트렌드" : "Trends" }
    var tabSettings: String { lang == .ko ? "설정" : "Settings" }

    // MARK: - Today
    var byModel: String { lang == .ko ? "모델별" : "By Model" }
    var noDataYet: String { lang == .ko ? "데이터 없음" : "No data yet" }
    func tokens(_ count: Int) -> String {
        "/ \(formatFull(count)) \(lang == .ko ? "토큰" : "tokens")"
    }
    func dayStreak(_ n: Int) -> String {
        lang == .ko ? "\(n)일 연속" : "\(n) day streak"
    }

    // MARK: - Trends
    var chartDaily: String { lang == .ko ? "일별" : "Daily" }
    var chartHourly: String { lang == .ko ? "시간대" : "Hourly" }
    var chartModels: String { lang == .ko ? "모델" : "Models" }
    var goal: String { lang == .ko ? "목표" : "Goal" }
    var avgHourlyCaption: String {
        lang == .ko ? "시간대별 평균 토큰 (최근 14일)" : "Average tokens by hour (last 14 days)"
    }
    var modelDistCaption: String {
        lang == .ko ? "모델별 토큰 분포 (최근 14일)" : "Token distribution by model (last 14 days)"
    }

    // MARK: - Settings
    var dailyGoal: String { lang == .ko ? "일일 목표" : "Daily Goal" }
    var customGoal: String { lang == .ko ? "직접 입력" : "Custom goal" }
    var tokensUnit: String { lang == .ko ? "토큰" : "tokens" }
    var dayResetTime: String { lang == .ko ? "날짜 초기화 시각 (UTC)" : "Day Reset Time (UTC)" }
    func localTimeEq(_ hour: Int) -> String {
        String(format: lang == .ko ? "= 현지 %02d:00" : "= %02d:00 local", hour)
    }
    var streak: String { lang == .ko ? "스트릭" : "Streak" }
    var resetStreak: String { lang == .ko ? "스트릭 초기화" : "Reset Streak" }
    var resetStreakQuestion: String { lang == .ko ? "스트릭을 초기화할까요?" : "Reset Streak?" }
    var resetStreakMessage: String {
        lang == .ko ? "현재 스트릭이 0으로 초기화됩니다." : "This will reset your current streak to 0."
    }
    var cancel: String { lang == .ko ? "취소" : "Cancel" }
    var reset: String { lang == .ko ? "초기화" : "Reset" }
    var language: String { lang == .ko ? "언어" : "Language" }
    var quitApp: String { lang == .ko ? "TokenChallenge 종료" : "Quit TokenChallenge" }

    // MARK: - Number Formatting

    /// Compact format for menu bar, model breakdown, chart axes
    func formatCompact(_ n: Int) -> String {
        switch lang {
        case .en:
            if n >= 1_000_000 {
                let s = String(format: "%.1f", Double(n) / 1_000_000)
                return (s.hasSuffix(".0") ? String(s.dropLast(2)) : s) + "M"
            } else if n >= 1_000 {
                let s = String(format: "%.1f", Double(n) / 1_000)
                return (s.hasSuffix(".0") ? String(s.dropLast(2)) : s) + "K"
            }
            return formatWithCommas(n)
        case .ko:
            return formatKorean(n)
        }
    }

    /// Full format for counter display and goal labels
    func formatFull(_ n: Int) -> String {
        switch lang {
        case .en:
            return formatWithCommas(n)
        case .ko:
            return formatKorean(n)
        }
    }

    /// Preset button labels (compact, no commas)
    func formatPreset(_ n: Int) -> String {
        switch lang {
        case .en:
            if n >= 1_000_000 { return "\(n / 1_000_000)M" }
            if n >= 1_000 { return "\(n / 1_000)K" }
            return "\(n)"
        case .ko:
            if n >= 100_000_000 { return "\(n / 100_000_000)억" }
            if n >= 10_000 { return "\(n / 10_000)만" }
            return "\(n)"
        }
    }

    // MARK: - Private Helpers

    private func formatKorean(_ n: Int) -> String {
        if n >= 100_000_000 {
            return formatKoreanDecimal(Double(n) / 100_000_000) + "억"
        } else if n >= 10_000 {
            return formatKoreanDecimal(Double(n) / 10_000) + "만"
        }
        return formatWithCommas(n)
    }

    private func formatKoreanDecimal(_ val: Double) -> String {
        let rounded = (val * 10).rounded() / 10
        if rounded == Double(Int(rounded)) {
            return formatWithCommas(Int(rounded))
        }
        let intPart = Int(rounded)
        let fracPart = Int(((rounded - Double(intPart)) * 10).rounded())
        return formatWithCommas(intPart) + ".\(fracPart)"
    }

    private static let commaFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    private func formatWithCommas(_ n: Int) -> String {
        Self.commaFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
