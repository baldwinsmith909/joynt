import SwiftUI

struct StickyNoteView: View {
    let text: String
    var color: Color = JoyntTheme.stickyYellow
    var rotation: Double = -2.5
    var maxWidth: CGFloat = 220

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .default))
            .foregroundStyle(JoyntTheme.ink)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 14)
            .padding(.top, 22)
            .padding(.bottom, 14)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .offset(x: 4, y: 4)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.78))
                    .frame(width: 42, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                    .offset(y: -6)
                    .shadow(color: .black.opacity(0.12), radius: 0, x: 1, y: 1)
            }
            .rotationEffect(.degrees(rotation))
    }
}

struct BlankStickyComposer: View {
    @Binding var text: String
    var color: Color = JoyntTheme.stickyYellow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIONAL NOTE")
                .joyntMetaLabel()
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 2))
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black)
                            .offset(x: 5, y: 5)
                    )
                    .frame(minHeight: 110)

                if text.isEmpty {
                    Text("Leave blank — a photo is enough.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.black.opacity(0.35))
                        .padding(14)
                        .padding(.top, 8)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: 16, weight: .medium))
                    .padding(10)
                    .frame(minHeight: 110)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > JoyntTheme.noteMaxCharacters {
                            text = String(newValue.prefix(JoyntTheme.noteMaxCharacters))
                        }
                    }
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 48, height: 16)
                    .offset(y: -7)
            }

            Text("\(text.count)/\(JoyntTheme.noteMaxCharacters)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.45))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
