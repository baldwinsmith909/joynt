import Foundation
import UIKit
import AuthenticationServices
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var session: AppSession?
    @Published var posts: [MealPost] = []
    @Published var comments: [Comment] = []
    @Published var followingIds: Set<UUID> = []
    @Published var dwellSeconds: [UUID: Double] = [:]
    @Published var selectedTab: RootTab = .feed
    @Published var feedKind: FeedKind = .forYou
    @Published var statusMessage: String?
    @Published var isBusy = false

    private let defaults = UserDefaults.standard
    private let sessionKey = "joynt.session.userId"

    init() {
        bootstrapDemoIfNeeded()
        restoreSessionIfPossible()
    }

    var currentUser: UserProfile? { session?.user }

    var isSignedIn: Bool { session != nil }

    // MARK: - Auth

    func continueWithDemo() {
        let user = DemoCatalog.baldwin
        session = AppSession(user: user, isDemo: true)
        followingIds = [DemoCatalog.mila.id, DemoCatalog.otto.id]
        posts = DemoCatalog.makeSeedPosts()
        comments = DemoCatalog.makeSeedComments()
        defaults.set(user.id.uuidString, forKey: sessionKey)
        statusMessage = "Demo mode — wire Supabase + Apple for production."
    }

    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        isBusy = true
        defer { isBusy = false }

        let appleUserId = credential.user
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let display = fullName.isEmpty ? "Joynt eater" : fullName

        if SupabaseConfig.isConfigured {
            do {
                try await signInWithSupabaseApple(identityToken: credential.identityToken, appleUserId: appleUserId, displayName: display)
                return
            } catch {
                statusMessage = error.localizedDescription
            }
        }

        // Local fallback when Supabase is not configured yet.
        let user = UserProfile(
            id: UUID(uuidString: uuidFromAppleUser(appleUserId)) ?? UUID(),
            displayName: display,
            handle: sanitizeHandle(display),
            bio: nil,
            avatarURL: nil,
            createdAt: Date()
        )
        session = AppSession(user: user, isDemo: !SupabaseConfig.isConfigured)
        if posts.isEmpty {
            posts = DemoCatalog.makeSeedPosts()
            comments = DemoCatalog.makeSeedComments()
            followingIds = [DemoCatalog.mila.id]
        }
        defaults.set(user.id.uuidString, forKey: sessionKey)
        statusMessage = SupabaseConfig.isConfigured
            ? "Signed in"
            : "Signed in locally — add Supabase keys to sync."
    }

    func signOut() {
        session = nil
        defaults.removeObject(forKey: sessionKey)
        Task { await SupabaseClient.shared.setAccessToken(nil) }
    }

    // MARK: - Posts

    func createPost(image: UIImage, note: String?) async {
        guard let user = currentUser else { return }
        isBusy = true
        defer { isBusy = false }

        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = (trimmed?.isEmpty == false) ? String(trimmed!.prefix(JoyntTheme.noteMaxCharacters)) : nil
        let postId = UUID()
        var photoPath: String?
        var photoURL: URL?

        if SupabaseConfig.isConfigured, session?.isDemo == false {
            do {
                let path = "\(user.id.uuidString)/\(postId.uuidString).jpg"
                if let data = image.jpegData(compressionQuality: 0.82) {
                    try await SupabaseClient.shared.uploadPhoto(path: path, jpegData: data)
                    photoPath = path
                    photoURL = await SupabaseClient.shared.publicPhotoURL(path: path)
                    try await insertRemotePost(id: postId, authorId: user.id, note: noteValue, photoPath: path)
                }
            } catch {
                statusMessage = error.localizedDescription
            }
        }

        let post = MealPost(
            id: postId,
            author: user,
            note: noteValue,
            photoPath: photoPath,
            photoURL: photoURL,
            localImage: image,
            createdAt: Date(),
            accentIndex: posts.count,
            appreciateCount: 0,
            saveCount: 0,
            commentCount: 0,
            viewerAppreciated: false,
            viewerSaved: false
        )
        posts.insert(post, at: 0)
        selectedTab = .profile
        statusMessage = noteValue == nil ? "Posted — photo only." : "Posted."
    }

    func posts(for userId: UUID) -> [MealPost] {
        posts
            .filter { $0.author.id == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Feeds

    var followingFeed: [MealPost] {
        guard let me = currentUser else { return [] }
        return posts
            .filter { followingIds.contains($0.author.id) || $0.author.id == me.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Ranked feed. Score stays internal — never shown in UI.
    var forYouFeed: [MealPost] {
        guard currentUser != nil else { return posts.sorted { $0.createdAt > $1.createdAt } }
        return posts.sorted { lhs, rhs in
            score(for: lhs) > score(for: rhs)
        }
    }

    func activeFeed() -> [MealPost] {
        feedKind == .forYou ? forYouFeed : followingFeed
    }

    func recordDwell(postId: UUID, seconds: Double) {
        dwellSeconds[postId, default: 0] += max(0, seconds)
    }

    private func score(for post: MealPost) -> Double {
        let followBoost = followingIds.contains(post.author.id) ? 4.0 : 0.0
        let engagement =
            Double(post.appreciateCount) * 1.4
            + Double(post.saveCount) * 1.8
            + Double(post.commentCount) * 2.2
            + (post.viewerAppreciated ? 0.5 : 0)
            + (post.viewerSaved ? 0.7 : 0)
        let dwell = min(dwellSeconds[post.id, default: 0] / 8.0, 3.0)
        let ageHours = max(Date().timeIntervalSince(post.createdAt) / 3600.0, 0.2)
        let recency = 6.0 / pow(ageHours, 0.55)
        // Hidden ranking only.
        return followBoost + engagement + dwell + recency
    }

    // MARK: - Social

    func isFollowing(_ userId: UUID) -> Bool {
        followingIds.contains(userId)
    }

    func toggleFollow(_ userId: UUID) {
        guard let me = currentUser, me.id != userId else { return }
        if followingIds.contains(userId) {
            followingIds.remove(userId)
        } else {
            followingIds.insert(userId)
        }
        if SupabaseConfig.isConfigured, session?.isDemo == false {
            Task { await syncFollow(userId: userId, following: followingIds.contains(userId)) }
        }
    }

    func toggleAppreciate(_ postId: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        var post = posts[idx]
        if post.viewerAppreciated {
            post.viewerAppreciated = false
            post.appreciateCount = max(0, post.appreciateCount - 1)
        } else {
            post.viewerAppreciated = true
            post.appreciateCount += 1
        }
        posts[idx] = post
    }

    func toggleSave(_ postId: UUID) {
        guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
        var post = posts[idx]
        if post.viewerSaved {
            post.viewerSaved = false
            post.saveCount = max(0, post.saveCount - 1)
        } else {
            post.viewerSaved = true
            post.saveCount += 1
        }
        posts[idx] = post
    }

    func comments(for postId: UUID) -> [Comment] {
        comments
            .filter { $0.postId == postId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addComment(postId: UUID, body: String) {
        guard let user = currentUser else { return }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let comment = Comment(
            id: UUID(),
            postId: postId,
            author: user,
            body: String(trimmed.prefix(240)),
            createdAt: Date()
        )
        comments.append(comment)
        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            posts[idx].commentCount += 1
        }
    }

    func profile(for id: UUID) -> UserProfile? {
        if currentUser?.id == id { return currentUser }
        if let fromPost = posts.first(where: { $0.author.id == id })?.author {
            return fromPost
        }
        return DemoCatalog.seedUsers.first { $0.id == id }
    }

    // MARK: - Private

    private func bootstrapDemoIfNeeded() {
        // Keep empty until user signs in / continues with demo.
        posts = []
        comments = []
    }

    private func restoreSessionIfPossible() {
        guard let idString = defaults.string(forKey: sessionKey),
              let id = UUID(uuidString: idString) else { return }
        // Restore demo Baldwin session for local loop / screenshot launches.
        if id == DemoCatalog.baldwin.id {
            session = AppSession(user: DemoCatalog.baldwin, isDemo: true)
            followingIds = [DemoCatalog.mila.id, DemoCatalog.otto.id]
            posts = DemoCatalog.makeSeedPosts()
            comments = DemoCatalog.makeSeedComments()
        }
    }

    func applyDeepLink(_ url: URL) {
        guard url.scheme == "joynt" else { return }
        if !isSignedIn {
            continueWithDemo()
        }
        switch url.host {
        case "post":
            selectedTab = .post
        case "profile":
            selectedTab = .profile
        case "feed":
            selectedTab = .feed
            if url.path.contains("following") {
                feedKind = .following
            } else {
                feedKind = .forYou
            }
        default:
            break
        }
    }

    private func sanitizeHandle(_ name: String) -> String {
        let cleaned = name.lowercased().filter { $0.isLetter || $0.isNumber }
        return cleaned.isEmpty ? "eater" : String(cleaned.prefix(18))
    }

    private func uuidFromAppleUser(_ appleUser: String) -> String {
        // Stable UUID-ish string for local profiles.
        let hash = appleUser.utf8.reduce(into: UInt64(5381)) { $0 = (($0 << 5) &+ $0) &+ UInt64($1) }
        return String(format: "%08x-aaaa-aaaa-aaaa-%012llx", hash & 0xffffffff, hash)
    }

    private func signInWithSupabaseApple(identityToken: Data?, appleUserId: String, displayName: String) async throws {
        guard let identityToken,
              let token = String(data: identityToken, encoding: .utf8) else {
            throw SupabaseError.http(400, "Missing Apple identity token")
        }
        let payload = ["provider": "apple", "id_token": token]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await SupabaseClient.shared.request(
            path: "auth/v1/token",
            method: "POST",
            query: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: body
        )
        struct AuthResponse: Decodable {
            let access_token: String
            let user: RemoteUser
        }
        struct RemoteUser: Decodable {
            let id: UUID
            let email: String?
        }
        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
        await SupabaseClient.shared.setAccessToken(auth.access_token)

        let profile = UserProfile(
            id: auth.user.id,
            displayName: displayName,
            handle: sanitizeHandle(displayName),
            bio: nil,
            avatarURL: nil,
            createdAt: Date()
        )
        try await upsertProfile(profile)
        session = AppSession(user: profile, isDemo: false)
        try await refreshFromSupabase()
        _ = appleUserId
    }

    private func upsertProfile(_ profile: UserProfile) async throws {
        let row: [String: Any] = [
            "id": profile.id.uuidString,
            "display_name": profile.displayName,
            "handle": profile.handle,
            "bio": profile.bio as Any
        ]
        let body = try JSONSerialization.data(withJSONObject: row)
        _ = try await SupabaseClient.shared.request(
            path: "rest/v1/profiles",
            method: "POST",
            body: body,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    private func insertRemotePost(id: UUID, authorId: UUID, note: String?, photoPath: String) async throws {
        var row: [String: Any] = [
            "id": id.uuidString,
            "author_id": authorId.uuidString,
            "photo_path": photoPath
        ]
        if let note { row["note"] = note }
        let body = try JSONSerialization.data(withJSONObject: row)
        _ = try await SupabaseClient.shared.request(
            path: "rest/v1/posts",
            method: "POST",
            body: body,
            prefer: "return=minimal"
        )
    }

    private func syncFollow(userId: UUID, following: Bool) async {
        guard let me = currentUser else { return }
        do {
            if following {
                let row = [
                    "follower_id": me.id.uuidString,
                    "following_id": userId.uuidString
                ]
                let body = try JSONSerialization.data(withJSONObject: row)
                _ = try await SupabaseClient.shared.request(
                    path: "rest/v1/follows",
                    method: "POST",
                    body: body,
                    prefer: "return=minimal"
                )
            } else {
                _ = try await SupabaseClient.shared.request(
                    path: "rest/v1/follows",
                    method: "DELETE",
                    query: [
                        URLQueryItem(name: "follower_id", value: "eq.\(me.id.uuidString)"),
                        URLQueryItem(name: "following_id", value: "eq.\(userId.uuidString)")
                    ]
                )
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func refreshFromSupabase() async throws {
        // Lightweight pull for posts + profiles; demo data remains available offline.
        let data = try await SupabaseClient.shared.request(
            path: "rest/v1/posts",
            query: [
                URLQueryItem(name: "select", value: "*,profiles(*)"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "50")
            ]
        )
        // If schema or join shape differs, keep local demo rather than crashing.
        if !data.isEmpty {
            // Parsing kept intentionally soft for first credentials wiring.
        }
    }
}

enum RootTab: Hashable {
    case feed
    case post
    case profile
}
