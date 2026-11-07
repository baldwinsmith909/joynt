import Foundation

/// Fill these from your Supabase project settings (Project Settings → API).
/// Leave blank to run the local demo store (no network).
enum SupabaseConfig {
    static let urlString = ""
    static let anonKey = ""

    static var isConfigured: Bool {
        !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && URL(string: urlString) != nil
    }

    static var projectURL: URL? {
        URL(string: urlString)
    }
}
