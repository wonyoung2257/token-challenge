import SwiftUI

struct PopoverContentView: View {
    let store: TokenDataStore
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                Text(store.l10n.tabToday).tag(0)
                Text(store.l10n.tabTrends).tag(1)
                Text(store.l10n.tabSettings).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Tab content
            switch selectedTab {
            case 0:
                TodayView(store: store)
            case 1:
                TrendsView(store: store)
            case 2:
                SettingsView(store: store)
            default:
                TodayView(store: store)
            }
        }
        .frame(width: 360, height: 460)
    }
}
