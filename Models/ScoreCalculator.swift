import Foundation

// MARK: - Score Calculator Models

struct ScoreCriterion: Identifiable {
    let id = UUID()
    let label: String
    let points: Int
    let detail: String
}

struct RiskCategory {
    let name: String
    let range: ClosedRange<Int>
    let mortality: String
    let recommendation: String
    let isHighlighted: Bool  // red emphasis
}

struct ScoreCalculator: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let criteria: [ScoreCriterion]
    let riskCategories: [RiskCategory]
    let footnotes: [String]
    let externalLinkTitle: String?
    let externalLinkURL: String?
}

// MARK: - Risk category lookup

extension ScoreCalculator {
    func riskCategory(for score: Int) -> RiskCategory? {
        riskCategories.first { $0.range.contains(score) }
    }
}

// MARK: - Share Text

extension ScoreCalculator {
    func shareText(selectedIndices: Set<Int>, totalScore: Int) -> String {
        var lines: [String] = []
        lines.append(title.uppercased())
        lines.append(subtitle)
        lines.append("")

        lines.append("Selected criteria:")
        for i in selectedIndices.sorted() {
            let c = criteria[i]
            lines.append("  ✓ \(c.label) (+\(c.points))")
        }
        lines.append("")
        lines.append("Total score: \(totalScore)")

        if let cat = riskCategory(for: totalScore) {
            lines.append("Risk class: \(cat.name)")
            lines.append("30-day mortality: \(cat.mortality)")
            lines.append("Recommendation: \(cat.recommendation)")
        }

        lines.append("")

        if !footnotes.isEmpty {
            lines.append("── Key Principles ──")
            for note in footnotes {
                let clean = note
                    .replacingOccurrences(of: "!!", with: "")
                    .replacingOccurrences(of: "**", with: "")
                lines.append("  • \(clean)")
            }
        }

        lines.append("")
        lines.append("— Rapid Response Clinical Reference")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Static Data

extension ScoreCalculator {

    static let allScoreCalculators: [ScoreCalculator] = []
}
