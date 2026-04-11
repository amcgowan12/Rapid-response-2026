import SwiftUI

extension Color {
    static let rrPageBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1)
            : UIColor(red: 0.875, green: 0.910, blue: 0.945, alpha: 1)
    })
    static let rrSectionBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1)
            : UIColor(red: 0.965, green: 0.978, blue: 0.992, alpha: 1)
    })
    static let rrNeutralCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.15, blue: 0.19, alpha: 1)
            : UIColor(red: 0.985, green: 0.992, blue: 0.998, alpha: 1)
    })
    static let rrEmphasisBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.23, green: 0.27, blue: 0.33, alpha: 1)
            : UIColor(red: 0.820, green: 0.872, blue: 0.925, alpha: 1)
    })
    static let rrDarkAccentText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.65, green: 0.76, blue: 0.90, alpha: 1)
            : UIColor(red: 0.10, green: 0.20, blue: 0.34, alpha: 1)
    })
    static let rrCheckmarkGreen = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.75, blue: 0.50, alpha: 1)
            : UIColor(red: 0.18, green: 0.43, blue: 0.28, alpha: 1)
    })
}

struct SectionCard: View {
    let section: TopicSection
    let isFirstSection: Bool
    let isExpanded: Bool
    let onTap: () -> Void

    private struct SectionStyle {
        let symbolName: String
        let color: Color
    }

    /// Accent color based on section content type
    private var tintColor: Color {
        if let style = standardizedStyle {
            return style.color
        }

        switch section.content {
        case .bullets:      return .blue
        case .steps:        return .orange
        case .keyValue:     return .purple
        case .drugTable:    return .green
        case .imageGallery: return .pink
        }
    }

    private var standardizedStyle: SectionStyle? {
        let normalizedTitle = section.title.lowercased()

        if normalizedTitle.contains("workup") || normalizedTitle.contains("evaluation") || normalizedTitle.contains("diagnostic") {
            return SectionStyle(symbolName: "stethoscope", color: .blue)
        }

        if normalizedTitle.contains("management") || normalizedTitle.contains("treatment") || normalizedTitle.contains("plan") {
            return SectionStyle(symbolName: "cross.case.fill", color: .orange)
        }

        if normalizedTitle.contains("medication") || normalizedTitle.contains("medications") || normalizedTitle.contains("drug") {
            return SectionStyle(symbolName: "pills.fill", color: .green)
        }

        return nil
    }

    private var showsSlimDividers: Bool {
        if case .keyValue = section.content {
            return true
        }
        return false
    }

    private var enablesTopicInference: Bool {
        showsSlimDividers
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text(isExpanded ? "Tap to collapse" : "Tap to expand")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(tintColor.opacity(0.12))
                            .frame(width: 30, height: 30)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(tintColor.opacity(0.8))
                            .font(.caption.weight(.bold))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.rrSectionBackground)
            }
            .buttonStyle(.plain)

            if isExpanded {
                SectionContentView(
                    sectionTitle: section.title,
                    content: section.content,
                    showsSlimDividers: showsSlimDividers,
                    enablesTopicInference: enablesTopicInference,
                    highlightsABC: isFirstSection
                )
                    .padding(16)
                    .background(Color.rrSectionBackground)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
