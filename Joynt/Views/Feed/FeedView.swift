import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var store: AppStore
    @State private var commentPost: MealPost?
    @State private var profileUserId: UUID?
    @State private var visiblePostId: UUID?

    var body: some View {
        ZStack(alignment: .top) {
            feedPager
            topChrome
        }
        .sheet(item: $commentPost) { post in
            CommentsSheet(post: post)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: Binding(
            get: { profileUserId.map { ProfileSheetItem(id: $0) } },
            set: { profileUserId = $0?.id }
        )) { item in
            NavigationStack {
                ProfileView(userId: item.id, isSelf: item.id == store.currentUser?.id)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") { profileUserId = nil }
                        }
                    }
            }
        }
    }

    private var topChrome: some View {
        HStack(spacing: 18) {
            ForEach(FeedKind.allCases) { kind in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.feedKind = kind
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(kind.rawValue)
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(store.feedKind == kind ? Color.black : Color.black.opacity(0.35))
                        Rectangle()
                            .fill(store.feedKind == kind ? JoyntTheme.lime : Color.clear)
                            .frame(height: 4)
                            .overlay(Rectangle().stroke(store.feedKind == kind ? Color.black : Color.clear, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(
            JoyntTheme.cream.opacity(0.92)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.black).frame(height: 2)
                }
        )
    }

    private var feedPager: some View {
        let items = store.activeFeed()
        return Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { post in
                            MealPosterCard(
                                post: post,
                                onAppreciate: { store.toggleAppreciate(post.id) },
                                onSave: { store.toggleSave(post.id) },
                                onComment: { commentPost = post },
                                onOpenAuthor: { profileUserId = post.author.id }
                            )
                            .containerRelativeFrame(.vertical)
                            .onAppear {
                                visiblePostId = post.id
                            }
                            .onDisappear {
                                if visiblePostId == post.id {
                                    store.recordDwell(postId: post.id, seconds: 4)
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: 54)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 72)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(store.feedKind == .following ? "Follow someone\nto fill this feed." : "No meals yet.\nPost the first one.")
                .joyntPosterType(32)
                .multilineTextAlignment(.center)
            BlackPillButton(title: "Post a meal", offsetColor: JoyntTheme.lime) {
                store.selectedTab = .post
            }
            Spacer()
        }
        .padding()
    }
}

private struct ProfileSheetItem: Identifiable {
    let id: UUID
}
