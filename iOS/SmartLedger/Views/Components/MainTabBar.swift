import SwiftUI

struct MainTabBar: View {
    @Binding var selectedTab: AppTab
    let theme: ThemeColors

    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? theme.primary : .textMuted)
                        Text(LocalizedStringKey(tab.localizationKey))
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? theme.primary : .textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.borderLight).frame(height: 1)
        }
    }
}

struct CreditsBadge: View {
    let credits: Int
    let theme: ThemeColors
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("\(credits)")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(theme.primaryDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.tintBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("credits.badge")
    }
}

struct AIAssistantAvatar: View {
    let theme: ThemeColors
    var size: CGFloat = 40

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.4, style: .continuous)
            .fill(theme.primary)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "cpu")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: theme.primary.opacity(0.25), radius: 4, y: 2)
    }
}
