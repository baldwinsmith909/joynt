import SwiftUI

struct PosterFrame<Content: View>: View {
    var accent: Color = JoyntTheme.lime
    @ViewBuilder var content: Content

    var body: some View {
        content
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: JoyntTheme.frameWidth))
            .background(
                Rectangle()
                    .fill(Color.black)
                    .offset(x: JoyntTheme.hardShadow.width, y: JoyntTheme.hardShadow.height)
            )
    }
}

struct MealPosterCard: View {
    let post: MealPost
    var showsSticky: Bool = true
    var showsActions: Bool = true
    var onAppreciate: (() -> Void)?
    var onSave: (() -> Void)?
    var onComment: (() -> Void)?
    var onOpenAuthor: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                accentField
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 14)

                    Spacer(minLength: 8)

                    poster
                        .padding(.horizontal, 18)
                        .frame(maxHeight: geo.size.height * 0.62)

                    Spacer(minLength: 8)

                    if showsActions {
                        actions
                            .padding(.horizontal, 18)
                            .padding(.bottom, 28)
                    }
                }
            }
        }
    }

    private var accentField: some View {
        JoyntTheme.accent(for: post.accentIndex)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(post.mealLabel)
                    .joyntMetaLabel()
                Button {
                    onOpenAuthor?()
                } label: {
                    Text(post.author.displayName)
                        .joyntPosterType(28)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            quietCounts
        }
    }

    private var quietCounts: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if post.appreciateCount > 0 {
                Text("\(post.appreciateCount) appreciated")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
            }
            if post.commentCount > 0 {
                Text("\(post.commentCount) notes")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
            }
        }
    }

    private var poster: some View {
        PosterFrame(accent: JoyntTheme.accent(for: post.accentIndex)) {
            ZStack(alignment: .bottomLeading) {
                mealImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                if showsSticky, let note = post.note, !note.isEmpty {
                    StickyNoteView(text: note, color: stickyColor, rotation: -2.2)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JoyntTheme.creamDeep)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }

    @ViewBuilder
    private var mealImage: some View {
        if let uiImage = post.localImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let url = post.photoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    ProgressView().tint(.black)
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            JoyntTheme.creamDeep
            VStack(spacing: 10) {
                Circle()
                    .fill(JoyntTheme.accent(for: post.accentIndex))
                    .frame(width: 88, height: 88)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                Text("MEAL")
                    .joyntMetaLabel()
            }
        }
    }

    private var stickyColor: Color {
        [JoyntTheme.stickyYellow, JoyntTheme.stickyPink, JoyntTheme.mint, JoyntTheme.lavender][post.accentIndex % 4]
    }

    private var actions: some View {
        HStack(spacing: 16) {
            OutlineCircleButton(systemName: post.viewerAppreciated ? "hand.thumbsup.fill" : "hand.thumbsup", filled: post.viewerAppreciated) {
                onAppreciate?()
            }
            .accessibilityLabel("Appreciate")

            OutlineCircleButton(systemName: post.viewerSaved ? "bookmark.fill" : "bookmark", filled: post.viewerSaved) {
                onSave?()
            }
            .accessibilityLabel("Save")

            OutlineCircleButton(systemName: "text.bubble") {
                onComment?()
            }
            .accessibilityLabel("Comment")

            Spacer()
        }
    }
}
