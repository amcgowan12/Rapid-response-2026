import Foundation

struct Topic: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String    // Short description shown on the home screen
    let sections: [TopicSection]

    /// Formatted plain-text summary for sharing / exporting
    var shareText: String {
        var lines: [String] = []
        lines.append(title.uppercased())
        lines.append(subtitle)
        lines.append("")

        for section in sections {
            lines.append("── \(section.title) ──")

            switch section.content {
            case .bullets(let items):
                for item in items {
                    lines.append("  • \(stripMarkup(item))")
                }

            case .steps(let items):
                var stepNumber = 0
                for item in items {
                    let stripped = stripMarkup(item).trimmingCharacters(in: .whitespacesAndNewlines)
                    if let nested = nestedStepText(from: stripped) {
                        lines.append("    - \(nested)")
                    } else {
                        stepNumber += 1
                        lines.append("  \(stepNumber). \(stripped)")
                    }
                }

            case .keyValue(let pairs):
                for pair in pairs {
                    lines.append("  \(pair.key): \(stripMarkup(pair.value))")
                }

            case .drugTable(let drugs):
                for drug in drugs {
                    var line = "  \(drug.name) — \(drug.dose) (\(drug.route))"
                    if !drug.contraindications.isEmpty {
                        line += " | CI: \(stripMarkup(drug.contraindications))"
                    }
                    if !drug.notes.isEmpty {
                        line += " | \(stripMarkup(drug.notes))"
                    }
                    lines.append(line)
                }

            case .imageGallery(let images):
                for img in images {
                    lines.append("  [\(img.caption)] \(img.description)")
                }
            }
            lines.append("")
        }

        lines.append("— Rapid Response Clinical Reference")
        return lines.joined(separator: "\n")
    }

    /// Unique topic titles referenced via topicLink in this topic's keyValue sections
    var relatedTopicTitles: [String] {
        var seen = Set<String>()
        var titles: [String] = []
        for section in sections {
            if case .keyValue(let pairs) = section.content {
                for pair in pairs {
                    if let link = pair.topicLink, !seen.contains(link) {
                        seen.insert(link)
                        titles.append(link)
                    }
                }
            }
        }
        return titles
    }

    /// Strip !!red!! and **bold** markers from text
    private func stripMarkup(_ text: String) -> String {
        text.replacingOccurrences(of: "!!", with: "")
            .replacingOccurrences(of: "**", with: "")
    }

    private func nestedStepText(from item: String) -> String? {
        guard let first = item.first, ["-", "•", "*"].contains(first) else {
            return nil
        }

        let text = item.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : String(text)
    }
}
