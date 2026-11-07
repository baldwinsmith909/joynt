import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    let userId: UUID
    var isSelf: Bool = false

    private var user: UserProfile? { store.profile(for: userId) }
    private var meals: [MealPost] { store.posts(for: userId) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                followRow
                Text("MEAL POSTERS")
                    .joyntMetaLabel()
                    .padding(.top, 6)
                posterStack
            }
            .padding(20)
            .padding(.bottom, 110)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 8)
        }
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0)
                .fill(JoyntTheme.lavender)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                .background(Rectangle().fill(Color.black).offset(x: 5, y: 5))
                .frame(minHeight: 160)

            Circle()
                .fill(JoyntTheme.electricBlue)
                .frame(width: 110, height: 110)
                .offset(x: 240, y: -30)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                Text(isSelf ? "03 / YOU" : "03 / PROFILE")
                    .joyntMetaLabel()
                Text(user?.displayName ?? "Eater")
                    .joyntPosterType(36)
                if let handle = user?.handle {
                    Text("@\(handle)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.55))
                }
                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 15, weight: .medium))
                }
                Text("\(meals.count) meals")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(18)
        }
        .clipped()
    }

    @ViewBuilder
    private var followRow: some View {
        if !isSelf, let user {
            HStack {
                if store.isFollowing(user.id) {
                    Button {
                        store.toggleFollow(user.id)
                    } label: {
                        Text("Following")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(JoyntTheme.cream)
                                    .overlay(Capsule().stroke(Color.black, lineWidth: 2.5))
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    BlackPillButton(title: "Follow", offsetColor: JoyntTheme.mint) {
                        store.toggleFollow(user.id)
                    }
                }
                Spacer()
            }
        } else if isSelf {
            HStack {
                Button {
                    store.signOut()
                } label: {
                    Text("Sign out")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.55))
                }
                .buttonStyle(.plain)
                Spacer()
                if store.session?.isDemo == true {
                    Text("DEMO")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(JoyntTheme.lime)
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                }
            }
        }
    }

    private var posterStack: some View {
        LazyVStack(spacing: 18) {
            if meals.isEmpty {
                Text(isSelf ? "Your posters will stack here." : "No meals yet.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, post in
                    profilePoster(post, index: index)
                }
            }
        }
    }

    private func profilePoster(_ post: MealPost, index: Int) -> some View {
        PosterFrame(accent: JoyntTheme.accent(for: post.accentIndex)) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = post.localImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let url = post.photoURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                JoyntTheme.creamDeep
                            }
                        }
                    } else {
                        JoyntTheme.creamDeep
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(post.mealLabel)
                        .joyntMetaLabel()
                        .padding(8)
                        .background(JoyntTheme.cream.opacity(0.92))
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))

                    if let note = post.note, !note.isEmpty {
                        StickyNoteView(text: note, color: JoyntTheme.stickyYellow, rotation: Double([-2, 1.5, -1][index % 3]), maxWidth: 180)
                            .padding(12)
                    }
                }
            }
        }
    }
}
