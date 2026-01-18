import Foundation

// MARK: - Root Response
struct ScanResult: Codable {
    let feng_shui_score: Int
    let bagua_analysis: [BaguaZone]
    let suggestions: [Suggestion]
    let ui_hints: UIHints?
}

// MARK: - Sub-Models
struct BaguaZone: Codable {
    let zone: String // e.g., "wealth", "career"
    let score: Int
    let notes: String
}

struct Suggestion: Codable {
    let id: String
    let title: String
    let description: String
    let severity: String // "high", "medium", "low"
    let related_object_ids: [String]
}

struct UIHints: Codable {
    let highlight_objects: [String]
    let recommended_zones: [String]
}
