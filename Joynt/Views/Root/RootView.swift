import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.isSignedIn {
                MainShellView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isSignedIn)
    }
}

struct MainShellView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            CreamGridBackground()

            Group {
                switch store.selectedTab {
                case .feed:
                    FeedView()
                case .post:
                    ComposerView()
                case .profile:
                    if let user = store.currentUser {
                        ProfileView(userId: user.id, isSelf: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .ignoresSafeArea(.keyboard)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton("FEED", tab: .feed)
            Spacer()
            postButton
            Spacer()
            tabButton("YOU", tab: .profile)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(
            Rectangle()
                .fill(JoyntTheme.cream)
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.black).frame(height: 2)
                }
                .shadow(color: .black.opacity(0.08), radius: 0, x: 0, y: -2)
        )
    }

    private func tabButton(_ title: String, tab: RootTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                store.selectedTab = tab
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(store.selectedTab == tab ? Color.black : Color.black.opacity(0.35))
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .overlay(alignment: .bottom) {
                    if store.selectedTab == tab {
                        Rectangle()
                            .fill(JoyntTheme.coral)
                            .frame(height: 4)
                            .offset(y: 6)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var postButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                store.selectedTab = .post
            }
        } label: {
            Text("POST")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.black))
                .background(
                    Capsule()
                        .fill(JoyntTheme.lime)
                        .offset(x: 4, y: 4)
                )
                .scaleEffect(store.selectedTab == .post ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Post a meal")
    }
}
