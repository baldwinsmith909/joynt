import SwiftUI

struct BlackPillButton: View {
    let title: String
    var offsetColor: Color = JoyntTheme.coral
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.black))
                .background(
                    Capsule()
                        .fill(offsetColor)
                        .offset(x: 4, y: 4)
                )
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}

struct OutlineCircleButton: View {
    let systemName: String
    var filled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.black, lineWidth: 2.5)
                    .background(Circle().fill(filled ? Color.black : Color.clear))
                    .frame(width: 46, height: 46)
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(filled ? Color.white : Color.black)
            }
        }
        .buttonStyle(.plain)
    }
}
