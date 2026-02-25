import Foundation

// MARK: - JSONL Raw Models

struct JSONLEntry: Decodable {
    let type: String
    let timestamp: String?
    let message: AssistantMessage?
}

struct AssistantMessage: Decodable {
    let model: String?
    let usage: TokenUsage?
}

struct TokenUsage: Decodable {
    let input_tokens: Int?
    let output_tokens: Int?
    let cache_creation_input_tokens: Int?
    let cache_read_input_tokens: Int?

    var total: Int {
        (input_tokens ?? 0) + (output_tokens ?? 0) +
        (cache_creation_input_tokens ?? 0) + (cache_read_input_tokens ?? 0)
    }
}

// MARK: - App Models

struct TokenRecord: Identifiable {
    let id = UUID()
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
}

struct DailyUsage: Identifiable {
    let id: String // date string "yyyy-MM-dd"
    let date: Date
    var totalTokens: Int
    var byModel: [String: Int]
    var byHour: [Int: Int] // hour (0-23) -> tokens
    var records: [TokenRecord]
}

struct ChallengeSettings: Codable, Equatable {
    var dailyGoal: Int
    var resetHourUTC: Int // 0-23, default 15 (= midnight KST)
    var streak: Int
    var lastGoalMetDate: String? // "yyyy-MM-dd" in logical day
    var language: AppLanguage

    static let `default` = ChallengeSettings(
        dailyGoal: 10_000_000,
        resetHourUTC: 15,
        streak: 0,
        lastGoalMetDate: nil,
        language: .en
    )
}

// MARK: - File Cache

struct FileCacheEntry {
    let modificationDate: Date
    let fileSize: UInt64
    let records: [TokenRecord]
}

// MARK: - Helpers

enum GoalPreset: Int, CaseIterable, Identifiable {
    case fiveM = 5_000_000
    case tenM = 10_000_000
    case twentyM = 20_000_000
    case fiftyM = 50_000_000

    var id: Int { rawValue }
}
