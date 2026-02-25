import SwiftUI
import Charts

struct TrendsView: View {
    let store: TokenDataStore
    @State private var chartMode = 0 // 0: daily, 1: hourly, 2: by model

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Picker("", selection: $chartMode) {
                    Text(store.l10n.chartDaily).tag(0)
                    Text(store.l10n.chartHourly).tag(1)
                    Text(store.l10n.chartModels).tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                switch chartMode {
                case 0: dailyChart
                case 1: hourlyChart
                case 2: modelChart
                default: dailyChart
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Daily Bar Chart

    @ViewBuilder
    private var dailyChart: some View {
        let days = store.recentDays.sorted { $0.date < $1.date }.suffix(7)
        if days.isEmpty {
            noDataView
        } else {
            Chart {
                ForEach(Array(days)) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Tokens", day.totalTokens)
                    )
                    .foregroundStyle(
                        day.totalTokens >= store.settings.dailyGoal
                            ? Color.green : Color.accentColor
                    )
                    .cornerRadius(4)
                }

                // Goal line
                RuleMark(y: .value("Goal", store.settings.dailyGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .trailing) {
                        Text(store.l10n.goal)
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text(store.l10n.formatCompact(intVal))
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Hourly Pattern Chart

    @ViewBuilder
    private var hourlyChart: some View {
        let hourlyData = aggregateHourly()
        if hourlyData.isEmpty {
            noDataView
        } else {
            Chart {
                ForEach(hourlyData, id: \.hour) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Tokens", item.tokens)
                    )
                    .foregroundStyle(Color.accentColor.opacity(0.7))
                    .cornerRadius(2)
                }
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let h = value.as(Int.self) {
                            Text("\(h)h")
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text(store.l10n.formatCompact(intVal))
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 16)

            Text(store.l10n.avgHourlyCaption)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Model Breakdown Chart

    @ViewBuilder
    private var modelChart: some View {
        let modelData = aggregateModels()
        if modelData.isEmpty {
            noDataView
        } else {
            Chart {
                ForEach(modelData, id: \.model) { item in
                    SectorMark(
                        angle: .value("Tokens", item.tokens),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Model", item.label))
                    .cornerRadius(3)
                }
            }
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 220)
            .padding(.horizontal, 16)

            Text(store.l10n.modelDistCaption)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text(store.l10n.noDataYet)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
    }

    struct HourlyItem {
        let hour: Int
        let tokens: Int
    }

    struct ModelItem {
        let model: String
        let label: String
        let tokens: Int
    }

    private func aggregateHourly() -> [HourlyItem] {
        var hourMap: [Int: [Int]] = [:]
        for day in store.recentDays {
            for (hour, tokens) in day.byHour {
                hourMap[hour, default: []].append(tokens)
            }
        }
        return (0..<24).compactMap { hour in
            let values = hourMap[hour] ?? []
            guard !values.isEmpty else { return HourlyItem(hour: hour, tokens: 0) }
            let avg = values.reduce(0, +) / max(values.count, 1)
            return HourlyItem(hour: hour, tokens: avg)
        }
    }

    private func aggregateModels() -> [ModelItem] {
        var modelMap: [String: Int] = [:]
        for day in store.recentDays {
            for (model, tokens) in day.byModel {
                modelMap[model, default: 0] += tokens
            }
        }
        return modelMap.map { model, tokens in
            let label = model
                .replacingOccurrences(of: "claude-", with: "")
                .replacingOccurrences(of: "-20250929", with: "")
                .replacingOccurrences(of: "-20251001", with: "")
            return ModelItem(model: model, label: label, tokens: tokens)
        }.sorted { $0.tokens > $1.tokens }
    }

}
