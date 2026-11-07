import Foundation
import UIKit

struct UserProfile: Identifiable, Hashable, Codable {
    var id: UUID
    var displayName: String
    var handle: String
    var bio: String?
    var avatarURL: URL?
    var createdAt: Date

    var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }
}

struct MealPost: Identifiable, Hashable {
    var id: UUID
    var author: UserProfile
    var note: String?
    var photoPath: String?
    var photoURL: URL?
    var localImage: UIImage?
    var createdAt: Date
    var accentIndex: Int
    var appreciateCount: Int
    var saveCount: Int
    var commentCount: Int
    var viewerAppreciated: Bool
    var viewerSaved: Bool

    var mealLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let hour = Int(formatter.string(from: createdAt)) ?? 12
        let slot: String
        switch hour {
        case 5..<11: slot = "BREAKFAST"
        case 11..<15: slot = "LUNCH"
        case 15..<17: slot = "SNACK"
        case 17..<22: slot = "DINNER"
        default: slot = "LATE"
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: createdAt) ?? 1
        return String(format: "%02d / %@", day % 100, slot)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MealPost, rhs: MealPost) -> Bool {
        lhs.id == rhs.id
            && lhs.appreciateCount == rhs.appreciateCount
            && lhs.saveCount == rhs.saveCount
            && lhs.commentCount == rhs.commentCount
            && lhs.viewerAppreciated == rhs.viewerAppreciated
            && lhs.viewerSaved == rhs.viewerSaved
            && lhs.note == rhs.note
    }
}

struct Comment: Identifiable, Hashable, Codable {
    var id: UUID
    var postId: UUID
    var author: UserProfile
    var body: String
    var createdAt: Date
}

enum FeedKind: String, CaseIterable, Identifiable {
    case forYou = "FOR YOU"
    case following = "FOLLOWING"

    var id: String { rawValue }
}

struct AppSession: Equatable {
    var user: UserProfile
    var isDemo: Bool
}
