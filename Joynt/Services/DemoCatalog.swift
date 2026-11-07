import Foundation
import UIKit
import SwiftUI

enum DemoCatalog {
    static let baldwin = UserProfile(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        displayName: "Baldwin",
        handle: "baldwin",
        bio: "Meals, not ratings.",
        avatarURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 40)
    )

    static let mila = UserProfile(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        displayName: "Mila Chen",
        handle: "mila",
        bio: "Tuesday noodles forever.",
        avatarURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 90)
    )

    static let otto = UserProfile(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        displayName: "Otto Reyes",
        handle: "otto",
        bio: "Breakfast is a lifestyle.",
        avatarURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 20)
    )

    static let june = UserProfile(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        displayName: "June Park",
        handle: "june",
        bio: "Quiet tables.",
        avatarURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 12)
    )

    static var seedUsers: [UserProfile] { [baldwin, mila, otto, june] }

    static func makeSeedPosts() -> [MealPost] {
        let now = Date()
        return [
            MealPost(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!,
                author: mila,
                note: "Tuesday noodles. No notes needed, but here we are.",
                photoPath: nil,
                photoURL: nil,
                localImage: syntheticMeal(hue: 0.08, label: "NOODLES"),
                createdAt: now.addingTimeInterval(-3600 * 2),
                accentIndex: 0,
                appreciateCount: 12,
                saveCount: 3,
                commentCount: 2,
                viewerAppreciated: false,
                viewerSaved: false
            ),
            MealPost(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!,
                author: otto,
                note: nil,
                photoPath: nil,
                photoURL: nil,
                localImage: syntheticMeal(hue: 0.12, label: "TOAST"),
                createdAt: now.addingTimeInterval(-3600 * 5),
                accentIndex: 1,
                appreciateCount: 4,
                saveCount: 1,
                commentCount: 0,
                viewerAppreciated: false,
                viewerSaved: false
            ),
            MealPost(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!,
                author: june,
                note: "Lemon on everything.",
                photoPath: nil,
                photoURL: nil,
                localImage: syntheticMeal(hue: 0.45, label: "SALAD"),
                createdAt: now.addingTimeInterval(-3600 * 9),
                accentIndex: 2,
                appreciateCount: 8,
                saveCount: 5,
                commentCount: 1,
                viewerAppreciated: true,
                viewerSaved: false
            ),
            MealPost(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4")!,
                author: mila,
                note: "Late soup.",
                photoPath: nil,
                photoURL: nil,
                localImage: syntheticMeal(hue: 0.02, label: "SOUP"),
                createdAt: now.addingTimeInterval(-3600 * 26),
                accentIndex: 3,
                appreciateCount: 2,
                saveCount: 0,
                commentCount: 0,
                viewerAppreciated: false,
                viewerSaved: false
            ),
            MealPost(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5")!,
                author: otto,
                note: "Coffee and a soft roll.",
                photoPath: nil,
                photoURL: nil,
                localImage: syntheticMeal(hue: 0.55, label: "ROLL"),
                createdAt: now.addingTimeInterval(-3600 * 30),
                accentIndex: 4,
                appreciateCount: 15,
                saveCount: 7,
                commentCount: 3,
                viewerAppreciated: false,
                viewerSaved: true
            )
        ]
    }

    static func makeSeedComments() -> [Comment] {
        [
            Comment(
                id: UUID(),
                postId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!,
                author: otto,
                body: "This looks perfect.",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            Comment(
                id: UUID(),
                postId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!,
                author: june,
                body: "I can smell it from here.",
                createdAt: Date().addingTimeInterval(-900)
            ),
            Comment(
                id: UUID(),
                postId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!,
                author: mila,
                body: "Lemon forever.",
                createdAt: Date().addingTimeInterval(-400)
            )
        ]
    }

    /// Procedural meal image so the demo works without asset packs.
    static func syntheticMeal(hue: CGFloat, label: String) -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(hue: hue, saturation: 0.35, brightness: 0.92, alpha: 1).setFill()
            ctx.fill(rect)

            UIColor(hue: hue + 0.08, saturation: 0.55, brightness: 0.75, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 120, y: 280, width: 660, height: 520)).fill()

            UIColor(hue: hue + 0.15, saturation: 0.7, brightness: 0.55, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 260, y: 420, width: 380, height: 280)).fill()

            UIColor.black.setStroke()
            let border = UIBezierPath(rect: rect.insetBy(dx: 18, dy: 18))
            border.lineWidth = 8
            border.stroke()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .black),
                .foregroundColor: UIColor.black
            ]
            let text = label as NSString
            let textSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: size.height - 140),
                withAttributes: attrs
            )
        }
    }
}
