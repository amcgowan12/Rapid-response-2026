import SwiftUI

// MARK: - Color helper

private func colorFromString(_ name: String) -> Color {
    switch name.lowercased() {
    case "red":    return .red
    case "blue":   return .blue
    case "green":  return .green
    case "orange": return .orange
    case "purple": return .purple
    case "pink":   return .pink
    case "yellow": return .yellow
    case "teal":   return .teal
    case "indigo": return .indigo
    case "brown":  return .brown
    default:       return .gray
    }
}

// MARK: - JSON Decodable structs

struct JSONOrganSystem: Decodable {
    let name: String
    let icon: String
    let color: String
    let topics: [JSONTopic]
}

struct JSONTopic: Decodable {
    let title: String
    let subtitle: String
    let sections: [JSONSection]
}

struct JSONSection: Decodable {
    let title: String
    let type: String
    let items: [String]?
    let pairs: [JSONPair]?
    let drugs: [JSONDrug]?
    let images: [JSONImage]?
}

struct JSONImage: Decodable {
    let assetName: String
    let caption: String?
    let description: String?
}

struct JSONPair: Decodable {
    let key: String
    let value: String
    let topicLink: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        value = try c.decode(String.self, forKey: .value)
        topicLink = try c.decodeIfPresent(String.self, forKey: .topicLink)
    }
    private enum CodingKeys: String, CodingKey {
        case key, value, topicLink
    }
}

struct JSONDrug: Decodable {
    let name: String
    let dose: String
    let route: String
    let contraindications: String?
    let notes: String
}

// MARK: - Shared mapping function

func mapSystem(_ sys: JSONOrganSystem) -> OrganSystem {
    OrganSystem(
        name: sys.name,
        icon: sys.icon,
        color: colorFromString(sys.color),
        topics: sys.topics.map { topic in
            Topic(
                title: topic.title,
                subtitle: topic.subtitle,
                sections: topic.sections.compactMap { sec in
                    let content: SectionContent
                    switch sec.type {
                    case "bullets":
                        content = .bullets(sec.items ?? [])
                    case "steps":
                        content = .steps(sec.items ?? [])
                    case "keyValue":
                        content = .keyValue((sec.pairs ?? []).map {
                            KeyValuePair(key: $0.key, value: $0.value, topicLink: $0.topicLink)
                        })
                    case "drugTable":
                        content = .drugTable((sec.drugs ?? []).map {
                            DrugEntry(name: $0.name, dose: $0.dose,
                                      route: $0.route,
                                      contraindications: $0.contraindications ?? "",
                                      notes: $0.notes)
                        })
                    case "imageGallery":
                        let expandedImages = (sec.images ?? []).map {
                            ImageEntry(
                                assetName: $0.assetName,
                                caption: $0.caption ?? $0.assetName,
                                description: $0.description ?? ""
                            )
                        }

                        let shorthandImages = (sec.items ?? []).map(parseImageShortcut)
                        content = .imageGallery(expandedImages + shorthandImages)
                    default:
                        print("⚠️ Unknown section type: \(sec.type)")
                        return nil
                    }
                    return TopicSection(title: sec.title, content: content)
                }
            )
        }
    )
}

private func parseImageShortcut(_ rawValue: String) -> ImageEntry {
    let parts = rawValue
        .split(separator: "|", omittingEmptySubsequences: false)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

    let assetName = parts.first ?? rawValue
    let caption = parts.count > 1 && !parts[1].isEmpty ? parts[1] : assetName
    let description = parts.count > 2 ? parts[2] : ""

    return ImageEntry(
        assetName: assetName,
        caption: caption,
        description: description
    )
}

// MARK: - Async data loader

@MainActor @Observable
final class DataLoader {
    static let shared = DataLoader()

    private(set) var conditionSystems: [OrganSystem] = []
    private(set) var symptomSystems: [OrganSystem] = []
    private(set) var isLoaded = false

    private init() {}

    func loadIfNeeded() {
        guard !isLoaded else { return }
        Task(priority: .userInitiated) {
            let conditions = decodeResource("content")
            let symptoms = decodeResource("Symptoms")
            self.conditionSystems = conditions
            self.symptomSystems = symptoms
            self.isLoaded = true
        }
    }
}

private func decodeResource(_ resource: String) -> [OrganSystem] {
    guard
        let url = Bundle.main.url(forResource: resource, withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let decoded = try? JSONDecoder().decode([JSONOrganSystem].self, from: data)
    else {
        print("⚠️ \(resource).json not found or failed to decode")
        return []
    }
    return decoded.map { mapSystem($0) }
}

// MARK: - Legacy accessors (kept for any other references)

extension OrganSystem {
    static var allSystems: [OrganSystem] { DataLoader.shared.conditionSystems }
}

enum SymptomSystem {
    static var allSystems: [OrganSystem] { DataLoader.shared.symptomSystems }
}
