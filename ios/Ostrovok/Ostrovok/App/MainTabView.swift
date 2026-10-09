import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        TabView(selection: $session.selectedTab) {
            CardsFeedView()
                .tabItem {
                    Label("Карточки", systemImage: "square.stack.3d.up")
                }
                .tag(AppTab.cards)

            AgentChatView()
                .tabItem {
                    Label("Агент", systemImage: "sparkles")
                }
                .tag(AppTab.agent)

            ProfileView()
                .tabItem {
                    Label("Кабинет", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)
        }
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
