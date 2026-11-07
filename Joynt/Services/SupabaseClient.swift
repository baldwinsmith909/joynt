import Foundation

/// Minimal Supabase REST + Storage client for the MVP.
/// Uses the anon key and PostgREST. Auth tokens are attached when present.
actor SupabaseClient {
    static let shared = SupabaseClient()

    private var accessToken: String?

    var isConfigured: Bool { SupabaseConfig.isConfigured }

    func setAccessToken(_ token: String?) {
        accessToken = token
    }

    func request(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        guard let base = SupabaseConfig.projectURL else {
            throw SupabaseError.notConfigured
        }
        var components = URLComponents(url: base.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw SupabaseError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        }
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SupabaseError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw SupabaseError.http(http.statusCode, message)
        }
        return data
    }

    func uploadPhoto(path: String, jpegData: Data) async throws {
        guard let base = SupabaseConfig.projectURL else { throw SupabaseError.notConfigured }
        let url = base.appending(path: "storage/v1/object/meal-photos/\(path)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken ?? SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = jpegData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "upload failed"
            throw SupabaseError.http((response as? HTTPURLResponse)?.statusCode ?? -1, message)
        }
    }

    func publicPhotoURL(path: String) -> URL? {
        SupabaseConfig.projectURL?
            .appending(path: "storage/v1/object/public/meal-photos/\(path)")
    }
}

enum SupabaseError: LocalizedError {
    case notConfigured
    case badURL
    case badResponse
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase is not configured. Add URL and anon key in SupabaseConfig.swift."
        case .badURL: return "Invalid Supabase URL."
        case .badResponse: return "Bad network response."
        case .http(let code, let message): return "Supabase \(code): \(message)"
        }
    }
}
