import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject private var store: AppStore
    @State private var appear = false

    var body: some View {
        ZStack {
            CreamGridBackground()

            VStack(spacing: 0) {
                heroBand
                Spacer(minLength: 24)
                posterBlock
                    .padding(.horizontal, 22)
                Spacer()
                actions
                    .padding(.horizontal, 22)
                    .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                appear = true
            }
        }
    }

    private var heroBand: some View {
        ZStack(alignment: .bottomLeading) {
            JoyntTheme.lime
                .ignoresSafeArea(edges: .top)
                .frame(height: 210)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(JoyntTheme.coral)
                        .frame(width: 140, height: 140)
                        .offset(x: 40, y: -30)
                }
                .overlay(Rectangle().stroke(Color.black, lineWidth: 2))

            VStack(alignment: .leading, spacing: 10) {
                Text("01 / MEALS")
                    .joyntMetaLabel()
                Text("Joynt")
                    .font(.system(size: 64, weight: .black))
                    .tracking(-2)
                    .foregroundStyle(.black)
                Text("Share the plate. Skip the score.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black.opacity(0.75))
            }
            .padding(22)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 16)
        }
    }

    private var posterBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A public meal feed.\nPhoto optional note.\nNo ratings.")
                .joyntPosterType(30)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                stickyChip("appreciate", JoyntTheme.stickyYellow)
                stickyChip("save", JoyntTheme.mint)
                stickyChip("comment", JoyntTheme.lavender)
            }
            .opacity(appear ? 1 : 0)
            .offset(x: appear ? 0 : -12)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JoyntTheme.cream)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
        .background(Rectangle().fill(Color.black).offset(x: 6, y: 6))
    }

    private func stickyChip(_ text: String, _ color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color)
            .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
            .background(Rectangle().fill(Color.black).offset(x: 3, y: 3))
    }

    private var actions: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                        Task { await store.handleAppleSignIn(credential: credential) }
                    }
                case .failure(let error):
                    store.statusMessage = error.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(Capsule())
            .background(Capsule().fill(JoyntTheme.coral).offset(x: 4, y: 4))

            Button {
                store.continueWithDemo()
            } label: {
                Text("Continue with demo meals")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(JoyntTheme.cream)
                            .overlay(Capsule().stroke(Color.black, lineWidth: 2.5))
                    )
            }
            .buttonStyle(.plain)

            if let status = store.statusMessage {
                Text(status)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.55))
                    .multilineTextAlignment(.center)
            }

            Text(SupabaseConfig.isConfigured ? "Supabase ready" : "Supabase keys not set — demo works offline")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.4))
        }
    }
}
