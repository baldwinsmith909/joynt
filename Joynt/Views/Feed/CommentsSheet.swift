import SwiftUI

struct CommentsSheet: View {
    @EnvironmentObject private var store: AppStore
    let post: MealPost
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            JoyntTheme.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().frame(height: 2).overlay(Color.black)
                list
                composer
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("COMMENTS")
                    .joyntMetaLabel()
                Text("Soft notes only")
                    .font(.system(size: 22, weight: .black))
            }
            Spacer()
            Button("Close") { dismiss() }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(18)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                let items = store.comments(for: post.id)
                if items.isEmpty {
                    Text("No comments yet. Leave a short note.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.black.opacity(0.45))
                        .padding(.top, 20)
                } else {
                    ForEach(items) { comment in
                        commentRow(comment)
                    }
                }
            }
            .padding(18)
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author.displayName)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text(comment.createdAt, style: .time)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.45))
            }
            Text(comment.body)
                .font(.system(size: 15, weight: .medium))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(JoyntTheme.stickyYellow)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                .background(Rectangle().fill(Color.black).offset(x: 3, y: 3))
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            Rectangle().fill(Color.black).frame(height: 2)
            HStack(spacing: 10) {
                TextField("Say something soft…", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(JoyntTheme.creamDeep)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
                Button {
                    store.addComment(postId: post.id, body: draft)
                    draft = ""
                } label: {
                    Text("Send")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.black))
                        .background(Capsule().fill(JoyntTheme.electricBlue).offset(x: 3, y: 3))
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(JoyntTheme.cream)
    }
}
