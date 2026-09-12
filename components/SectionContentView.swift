import SwiftUI

struct SectionContentView: View {
    let sectionTitle: String
    let content: SectionContent
    let showsSlimDividers: Bool
    let enablesTopicInference: Bool
    let highlightsABC: Bool
    let tintColor: Color
    var currentTopicTitle: String? = nil
    var drugLookup: [String: DrugEntry] = [:]
    @State private var expandedStepImages: Set<String> = []

    private static let plethExpandTrigger =
        "Confirm it is real: check waveform, probe, perfusion, and interface. Get ABG if severe or unclear."
    private static let plethReference = ImageEntry(
        assetName: "Pleth",
        caption: "Pleth",
        description: "Tap waveform quality to confirm the saturation is real before escalating."
    )

    private var usesManagementStepLayout: Bool {
        sectionTitle.localizedCaseInsensitiveContains("management")
    }

    private var usesCompactReferenceText: Bool {
        let lowercasedTitle = sectionTitle.lowercased()
        return lowercasedTitle.contains("ddx") || lowercasedTitle.contains("differential")
    }

    private var bodyFont: Font { .body }

    private var linksEntireCitationText: Bool {
        let lowercasedTitle = sectionTitle.lowercased()
        return lowercasedTitle.contains("references") || lowercasedTitle.contains("resources")
    }

    private func highlightedItems(_ items: [String]) -> [String] {
        guard highlightsABC else { return items }
        return items.map { highlightFirstWord(in: $0) }
    }

    private func highlightedPairs(_ pairs: [KeyValuePair]) -> [KeyValuePair] {
        return pairs
    }

    /// Wraps the first word of a line in `!!red!!` markers unless the line already has markup.
    private func highlightFirstWord(in text: String) -> String {
        guard !text.hasPrefix("!!"), !text.hasPrefix("~~"), !text.hasPrefix("-"), !text.hasPrefix("•") else { return text }
        guard let spaceIndex = text.firstIndex(of: " ") else { return text }
        let firstWord = String(text[text.startIndex..<spaceIndex])
        guard !firstWord.allSatisfy({ $0.isNumber || $0 == "." || $0 == ")" || $0 == "-" }) else { return text }
        return "!!\(firstWord)!!" + String(text[spaceIndex...])
    }
    
    var body: some View {
        Group {
        switch content {
            
        case .bullets(let items):
            let items = highlightedItems(items)
            if usesManagementStepLayout {
                stepList(items)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•").foregroundColor(.secondary)
                            LinkedText(text: item, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                                .font(bodyFont)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

        case .steps(let items):
            let items = highlightedItems(items)
            stepList(items)
            
        case .keyValue(let pairs):
            let pairs = highlightedPairs(pairs)
            if usesManagementStepLayout {
                keyValueStepList(pairs)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(pairs.enumerated()), id: \.element.id) { index, pair in
                        let isShaded = index.isMultiple(of: 2)
                        Group {
                            if let topic = resolvedTopic(for: pair) {
                                VStack(alignment: .leading, spacing: 2) {
                                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                                        Self.formattedText(pair.key)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color.rrDarkAccentText)
                                            .underline()
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)

                                    LinkedText(text: pair.value, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                                        .font(bodyFont)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 2) {
                                    Self.formattedText(pair.key)
                                        .font(.subheadline.weight(.semibold))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    LinkedText(text: pair.value, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                                        .font(bodyFont)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isShaded ? Color.rrEmphasisBackground.opacity(0.18) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
            
        case .drugTable(let drugs):
            DrugTableView(drugs: drugs)

        case .imageGallery(let images):
            ImageGalleryView(images: images)
        }
        }
    }

    private func resolvedTopic(for pair: KeyValuePair) -> Topic? {
        if let link = pair.topicLink,
           let topic = Self.findTopic(titled: link) {
            guard topic.title != currentTopicTitle else { return nil }
            return topic
        }

        guard enablesTopicInference else { return nil }
        let inferred = Self.inferTopic(from: pair.key)
        return inferred?.title == currentTopicTitle ? nil : inferred
    }

    static func findTopic(titled title: String) -> Topic? {
        let conditionTopics = OrganSystem.allSystems.flatMap(\.topics)
        let normalizedTitle = normalizedTopicKey(title)

        for topic in conditionTopics where topic.title == title {
            return topic
        }
        for topic in conditionTopics where normalizedTopicKey(topic.title) == normalizedTitle {
            return topic
        }
        return nil
    }

    static func inferTopic(from rawText: String) -> Topic? {
        let cleaned = cleanedTopicCandidate(rawText)
        let normalizedCandidate = normalizedTopicKey(cleaned)
        guard !normalizedCandidate.isEmpty else { return nil }

        let allTopics = OrganSystem.allSystems.flatMap(\.topics)

        if let exact = allTopics.first(where: { normalizedTopicKey($0.title) == normalizedCandidate }) {
            return exact
        }

        return allTopics.first {
            let normalizedTitle = normalizedTopicKey($0.title)
            return normalizedTitle.contains(normalizedCandidate) || normalizedCandidate.contains(normalizedTitle)
        }
    }

    private static func cleanedTopicCandidate(_ rawText: String) -> String {
        var cleaned = rawText
            .replacingOccurrences(of: "DDx:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Dx:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Etiology:", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Can't miss", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: CharacterSet(charactersIn: " :-–—"))

        if let parenIndex = cleaned.firstIndex(of: "(") {
            cleaned = String(cleaned[..<parenIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    private static func normalizedTopicKey(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private static func stepShowsPlethImage(_ item: String) -> Bool {
        item == plethExpandTrigger
    }

    private struct StepListEntry: Identifiable {
        let id: Int
        let text: String
        let stepNumber: Int?
        let isSubBullet: Bool
    }

    private var subBulletFont: Font { .footnote }

    private func parsedStepEntries(from items: [String]) -> [StepListEntry] {
        var entries: [StepListEntry] = []
        var currentStepNumber = 0

        for (index, rawItem) in items.enumerated() {
            let trimmed = rawItem.trimmingCharacters(in: .whitespacesAndNewlines)
            if let text = nestedStepText(from: trimmed) {
                entries.append(
                    StepListEntry(
                        id: index,
                        text: text,
                        stepNumber: nil,
                        isSubBullet: true
                    )
                )
            } else {
                currentStepNumber += 1
                entries.append(
                    StepListEntry(
                        id: index,
                        text: rawItem,
                        stepNumber: currentStepNumber,
                        isSubBullet: false
                    )
                )
            }
        }

        return entries
    }

    private func nestedStepText(from item: String) -> String? {
        guard let first = item.first, ["-", "•", "*"].contains(first) else {
            return nil
        }

        let text = item.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : String(text)
    }

    private func toggleStepImage(for item: String) {
        if expandedStepImages.contains(item) {
            expandedStepImages.remove(item)
        } else {
            expandedStepImages.insert(item)
        }
    }

    @ViewBuilder
    private func stepList(_ items: [String]) -> some View {
        let entries = parsedStepEntries(from: items)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(entries) { entry in
                if entry.isSubBullet {
                    HStack(alignment: .top, spacing: 6) {
                        Text("–")
                            .font(subBulletFont.weight(.semibold))
                            .foregroundColor(.secondary)
                        LinkedText(text: entry.text, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                            .font(subBulletFont)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 28)
                } else if Self.stepShowsPlethImage(entry.text) {
                    Button {
                        toggleStepImage(for: entry.text)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(entry.stepNumber ?? 0).")
                                .fontWeight(.semibold)
                                .foregroundColor(tintColor)
                                .frame(minWidth: 20, alignment: .leading)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    LinkedText(text: entry.text, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                                        .font(bodyFont)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Image(systemName: expandedStepImages.contains(entry.text) ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }

                                if expandedStepImages.contains(entry.text) {
                                    ImageGalleryView(images: [Self.plethReference])
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(entry.stepNumber ?? 0).")
                            .fontWeight(.semibold)
                            .foregroundColor(tintColor)
                            .frame(minWidth: 20, alignment: .leading)
                        LinkedText(text: entry.text, linkEntireCitationText: linksEntireCitationText, excludedTopicTitle: currentTopicTitle, drugLookup: drugLookup)
                            .font(bodyFont)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func keyValueStepList(_ pairs: [KeyValuePair]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(pairs.enumerated()), id: \.element.id) { index, pair in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .fontWeight(.semibold)
                        .foregroundColor(tintColor)
                        .frame(minWidth: 20, alignment: .leading)
                    Text("\(Self.formattedText(pair.key).fontWeight(.semibold)): \(Self.formattedText(pair.value))")
                    .font(bodyFont)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Parses `**bold**`, `!!red!!`, and `~~blue~~` markers and returns styled Text.
    /// Within `~~blue~~` segments, `**bold**` sub-markers apply bold weight while keeping blue color.
    static func formattedText(_ text: String) -> Text {
        let pattern = #"!!(.+?)!!|\*\*(.+?)\*\*|~~(.+?)~~"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return Text(verbatim: text)
        }
        var result = Text(verbatim: "")
        var lastEnd = text.startIndex
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text) else { continue }
            let plain = String(text[lastEnd..<range.lowerBound])
            if !plain.isEmpty { result = Text("\(result)\(Text(verbatim: plain))") }
            if let r = Range(match.range(at: 1), in: text) {
                result = Text("\(result)\(Text(verbatim: String(text[r])).foregroundColor(.red).fontWeight(.medium))")
            } else if let r = Range(match.range(at: 2), in: text) {
                result = Text("\(result)\(Text(verbatim: String(text[r])).fontWeight(.semibold))")
            } else if let r = Range(match.range(at: 3), in: text) {
                result = Text("\(result)\(blueStyledText(String(text[r])))")
            }
            lastEnd = range.upperBound
        }
        let remaining = String(text[lastEnd...])
        if !remaining.isEmpty { result = Text("\(result)\(Text(verbatim: remaining))") }
        return result
    }

    /// Renders text in blue, parsing any `**bold**` sub-markers as bold+blue.
    private static func blueStyledText(_ text: String) -> Text {
        let boldPattern = #"\*\*(.+?)\*\*"#
        guard let regex = try? NSRegularExpression(pattern: boldPattern) else {
            return Text(verbatim: text).foregroundColor(Color(.systemBlue))
        }
        var result = Text(verbatim: "")
        var lastEnd = text.startIndex
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let range = Range(match.range, in: text) else { continue }
            let plain = String(text[lastEnd..<range.lowerBound])
            if !plain.isEmpty {
                result = Text("\(result)\(Text(verbatim: plain).foregroundColor(Color(.systemBlue)))")
            }
            if let r = Range(match.range(at: 1), in: text) {
                result = Text("\(result)\(Text(verbatim: String(text[r])).foregroundColor(Color(.systemBlue)).fontWeight(.semibold))")
            }
            lastEnd = range.upperBound
        }
        let remaining = String(text[lastEnd...])
        if !remaining.isEmpty {
            result = Text("\(result)\(Text(verbatim: remaining).foregroundColor(Color(.systemBlue)))")
        }
        return result
    }

    func boldFormatted(_ text: String) -> Text {
        Self.formattedText(text)
    }
    // MARK: - Inline link renderer
    // Parses [text](url) patterns and renders them as tappable links
    
    struct LinkedText: View {
        let text: String
        var linkEntireCitationText = false
        var excludedTopicTitle: String? = nil
        var drugLookup: [String: DrugEntry] = [:]
        @State private var selectedTopic: Topic?
        @State private var tooltipText: String?
        @State private var selectedDrug: DrugEntry?
        
        private struct Segment {
            let text: String
            let url: URL?
            let topicTitle: String?
            let tooltipContent: String?
            let drugName: String?

            init(
                text: String,
                url: URL? = nil,
                topicTitle: String? = nil,
                tooltipContent: String? = nil,
                drugName: String? = nil
            ) {
                self.text = text
                self.url = url
                self.topicTitle = topicTitle
                self.tooltipContent = tooltipContent
                self.drugName = drugName
            }
        }

        private static let topicURLScheme = "rapidresponse-topic"
        private static let tooltipURLScheme = "rapidresponse-tooltip"
        private static let drugURLScheme = "rapidresponse-drug"
        private static let allTopicTitles: [String] = {
            let titles = OrganSystem.allSystems.flatMap(\.topics)
                .map(\.title)
            return Array(Set(titles)).sorted { lhs, rhs in
                if lhs.count == rhs.count { return lhs < rhs }
                return lhs.count > rhs.count
            }
        }()
        
        private var segments: [Segment] {
            var result: [Segment] = []
            var remaining = text
            // Matches http links AND __display|tooltip__ markers
            let pattern = #"\[([^\]]+)\]\((https?://[^\)]+)\)|__([^|_]+)\|([^_]+)__"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return [Segment(text: text, url: nil, topicTitle: nil, tooltipContent: nil)]
            }
            while !remaining.isEmpty {
                let range = NSRange(remaining.startIndex..., in: remaining)
                if let match = regex.firstMatch(in: remaining, range: range),
                   let fullRange = Range(match.range, in: remaining) {
                    let before = String(remaining[remaining.startIndex ..< fullRange.lowerBound])
                    if !before.isEmpty {
                        result.append(contentsOf: applyDrugMatching(Self.topicSegments(in: before, excluding: excludedTopicTitle)))
                    }
                    if let labelRange = Range(match.range(at: 1), in: remaining),
                       let urlRange   = Range(match.range(at: 2), in: remaining) {
                        // HTTP link
                        let label  = String(remaining[labelRange])
                        let urlStr = String(remaining[urlRange])
                        result.append(Segment(text: label, url: URL(string: urlStr), topicTitle: nil, tooltipContent: nil))
                    } else if let displayRange = Range(match.range(at: 3), in: remaining),
                              let contentRange = Range(match.range(at: 4), in: remaining) {
                        // Tooltip: __display text|tooltip content__
                        let display = String(remaining[displayRange])
                        let content = String(remaining[contentRange])
                        result.append(Segment(text: display, url: nil, topicTitle: nil, tooltipContent: content))
                    }
                    remaining = String(remaining[fullRange.upperBound...])
                } else {
                    result.append(contentsOf: applyDrugMatching(Self.topicSegments(in: remaining, excluding: excludedTopicTitle)))
                    break
                }
            }
            return result
        }
        
        var body: some View {
            if linkEntireCitationText,
               let citation = citationLinkPresentation {
                var attributed = AttributedString(citation.displayText)
                attributed.link = citation.url
                attributed.foregroundColor = Color.rrDarkAccentText
                attributed.underlineStyle = .single
                return AnyView(
                    Text(attributed)
                        .environment(\.openURL, OpenURLAction { url in
                            .systemAction(url)
                        })
                )
            }

            return AnyView(
            segments.reduce(Text("")) { accumulated, segment in
                if let name = segment.drugName,
                   let drugURL = Self.drugURL(for: name) {
                    var attributed = AttributedString(segment.text)
                    attributed.link = drugURL
                    attributed.foregroundColor = Color.rrCheckmarkGreen
                    attributed.underlineStyle = .single
                    return Text("\(accumulated)\(Text(attributed))")
                } else if let content = segment.tooltipContent,
                   let tooltipURL = Self.tooltipURL(for: content) {
                    var attributed = AttributedString(segment.text)
                    attributed.link = tooltipURL
                    attributed.foregroundColor = Color.primary
                    attributed.underlineStyle = .single
                    return Text("\(accumulated)\(Text(attributed))")
                } else if let linkURL = segment.url ?? Self.topicURL(for: segment.topicTitle) {
                    var attributed = AttributedString(segment.text)
                    attributed.link = linkURL
                    attributed.foregroundColor = Color.rrDarkAccentText
                    attributed.underlineStyle = .single
                    return Text("\(accumulated)\(Text(attributed))")
                } else {
                    return Text("\(accumulated)\(SectionContentView.formattedText(segment.text))")
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == Self.drugURLScheme {
                    if let name = Self.drugNameFromURL(url),
                       let drug = drugLookup[name] {
                        selectedDrug = drug
                    }
                    return .handled
                }
                if url.scheme == Self.tooltipURLScheme {
                    tooltipText = Self.tooltipContentFromURL(url)
                    return .handled
                }
                guard url.scheme == Self.topicURLScheme else {
                    return .systemAction(url)
                }
                guard
                    let title = Self.topicTitle(from: url),
                    let topic = SectionContentView.findTopic(titled: title)
                else {
                    return .discarded
                }
                selectedTopic = topic
                return .handled
            })
            .navigationDestination(isPresented: Binding(
                get: { selectedTopic != nil },
                set: { if !$0 { selectedTopic = nil } }
            )) {
                if let topic = selectedTopic {
                    TopicDetailView(topic: topic)
                }
            }
            .sheet(isPresented: Binding(
                get: { tooltipText != nil },
                set: { if !$0 { tooltipText = nil } }
            )) {
                TooltipSheetView(heading: "", detail: tooltipText ?? "")
                    .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
                    .presentationDragIndicator(Visibility.visible)
            }
            .sheet(item: $selectedDrug) { drug in
                DrugDetailSheetView(drug: drug)
                    .presentationDetents([PresentationDetent.medium, PresentationDetent.large])
                    .presentationDragIndicator(Visibility.visible)
            }
            )
        }

        private var citationLinkPresentation: (displayText: String, url: URL)? {
            let markdownPattern = #"\[([^\]]+)\]\((https?://[^\)]+)\)"#
            if let regex = try? NSRegularExpression(pattern: markdownPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let labelRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text),
               let url = URL(string: String(text[urlRange])) {
                return (String(text[labelRange]), url)
            }

            let urlPattern = #"https?://\S+"#
            if let regex = try? NSRegularExpression(pattern: urlPattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let urlRange = Range(match.range, in: text) {
                let rawURL = String(text[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: ".,);"))
                guard let url = URL(string: rawURL) else { return nil }

                var displayText = text.replacingOccurrences(of: String(text[urlRange]), with: "")
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if displayText.isEmpty {
                    displayText = rawURL
                }

                return (displayText, url)
            }

            let normalizedCitation = text
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "!!", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard
                !normalizedCitation.isEmpty,
                let query = normalizedCitation.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let fallbackURL = URL(string: "https://scholar.google.com/scholar?q=\(query)")
            else {
                return nil
            }

            return (normalizedCitation, fallbackURL)
        }

        private static func topicSegments(in rawText: String, excluding excludedTitle: String? = nil) -> [Segment] {
            guard !rawText.isEmpty else { return [] }

            var segments: [Segment] = []
            var cursor = rawText.startIndex

            while cursor < rawText.endIndex {
                var bestMatch: (range: Range<String.Index>, title: String)?

                for title in allTopicTitles {
                    if let excluded = excludedTitle,
                       title.lowercased() == excluded.lowercased() { continue }
                    guard
                        let range = rawText.range(
                            of: title,
                            options: [.caseInsensitive, .diacriticInsensitive],
                            range: cursor..<rawText.endIndex
                        ),
                        isValidTopicBoundary(in: rawText, range: range)
                    else {
                        continue
                    }

                    if let best = bestMatch {
                        if range.lowerBound < best.range.lowerBound ||
                            (range.lowerBound == best.range.lowerBound && title.count > best.title.count) {
                            bestMatch = (range, title)
                        }
                    } else {
                        bestMatch = (range, title)
                    }
                }

                guard let bestMatch else {
                    segments.append(Segment(text: String(rawText[cursor...]), url: nil, topicTitle: nil, tooltipContent: nil))
                    break
                }

                if cursor < bestMatch.range.lowerBound {
                    segments.append(
                        Segment(
                            text: String(rawText[cursor..<bestMatch.range.lowerBound]),
                            url: nil,
                            topicTitle: nil,
                            tooltipContent: nil
                        )
                    )
                }

                segments.append(
                    Segment(
                        text: String(rawText[bestMatch.range]),
                        url: nil,
                        topicTitle: bestMatch.title,
                        tooltipContent: nil
                    )
                )
                cursor = bestMatch.range.upperBound
            }

            return segments
        }

        private static func isValidTopicBoundary(in text: String, range: Range<String.Index>) -> Bool {
            let beforeIsBoundary: Bool
            if range.lowerBound == text.startIndex {
                beforeIsBoundary = true
            } else {
                let before = text[text.index(before: range.lowerBound)]
                beforeIsBoundary = !before.isLetter && !before.isNumber
            }

            let afterIsBoundary: Bool
            if range.upperBound == text.endIndex {
                afterIsBoundary = true
            } else {
                let after = text[range.upperBound]
                afterIsBoundary = !after.isLetter && !after.isNumber
            }

            return beforeIsBoundary && afterIsBoundary
        }

        private static func topicURL(for title: String?) -> URL? {
            guard let title else { return nil }
            var components = URLComponents()
            components.scheme = topicURLScheme
            components.host = "topic"
            components.queryItems = [URLQueryItem(name: "title", value: title)]
            return components.url
        }

        private static func topicTitle(from url: URL) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "title" })?
                .value
        }

        // Applies drug name detection to any plain-text (non-link) segment.
        private func applyDrugMatching(_ segs: [Segment]) -> [Segment] {
            guard !drugLookup.isEmpty else { return segs }
            return segs.flatMap { seg -> [Segment] in
                guard seg.url == nil, seg.topicTitle == nil,
                      seg.tooltipContent == nil, seg.drugName == nil else {
                    return [seg]
                }
                return Self.drugSegments(in: seg.text, lookup: drugLookup)
            }
        }

        private static func drugSegments(in rawText: String, lookup: [String: DrugEntry]) -> [Segment] {
            guard !rawText.isEmpty, !lookup.isEmpty else {
                return rawText.isEmpty ? [] : [Segment(text: rawText)]
            }
            let sortedKeys = lookup.keys.sorted { $0.count > $1.count }
            var segments: [Segment] = []
            var cursor = rawText.startIndex

            while cursor < rawText.endIndex {
                var bestMatch: (range: Range<String.Index>, key: String)?
                for key in sortedKeys {
                    guard let range = rawText.range(
                        of: key,
                        options: [.caseInsensitive, .diacriticInsensitive],
                        range: cursor..<rawText.endIndex
                    ), isValidTopicBoundary(in: rawText, range: range) else { continue }

                    if let best = bestMatch {
                        if range.lowerBound < best.range.lowerBound ||
                           (range.lowerBound == best.range.lowerBound && key.count > best.key.count) {
                            bestMatch = (range, key)
                        }
                    } else {
                        bestMatch = (range, key)
                    }
                }
                guard let bestMatch else {
                    segments.append(Segment(text: String(rawText[cursor...])))
                    break
                }
                if cursor < bestMatch.range.lowerBound {
                    segments.append(Segment(text: String(rawText[cursor..<bestMatch.range.lowerBound])))
                }
                segments.append(Segment(text: String(rawText[bestMatch.range]), drugName: bestMatch.key))
                cursor = bestMatch.range.upperBound
            }
            return segments
        }

        private static func drugURL(for name: String) -> URL? {
            var components = URLComponents()
            components.scheme = drugURLScheme
            components.host = "show"
            components.queryItems = [URLQueryItem(name: "drug", value: name)]
            return components.url
        }

        private static func drugNameFromURL(_ url: URL) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "drug" })?
                .value
        }

        private static func tooltipURL(for content: String) -> URL? {
            var components = URLComponents()
            components.scheme = tooltipURLScheme
            components.host = "show"
            components.queryItems = [URLQueryItem(name: "content", value: content)]
            return components.url
        }

        private static func tooltipContentFromURL(_ url: URL) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "content" })?
                .value
        }
    }
}

// MARK: - Tooltip sheet

private struct TooltipSheetView: View {
    let heading: String
    let detail: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !heading.isEmpty {
                        Text(heading)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                    }
                    Text(detail)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Drug detail popup sheet

private struct DrugDetailSheetView: View {
    let drug: DrugEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(drug.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Dose / Route", systemImage: "syringe")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        HStack(alignment: .top, spacing: 0) {
                            SectionContentView.formattedText(drug.dose)
                                .font(.body)
                            if !drug.route.isEmpty {
                                Text(" · \(drug.route)")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(Color.rrCheckmarkGreen)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    if !drug.contraindications.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Contraindications", systemImage: "exclamationmark.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            SectionContentView.formattedText(drug.contraindications)
                                .font(.body)
                                .foregroundColor(.red.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !drug.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Notes", systemImage: "note.text")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            SectionContentView.formattedText(drug.notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Drug Table with collapsible notes

struct DrugTableView: View {
    let drugs: [DrugEntry]
    @State private var expandedDrugs: Set<UUID> = []

    private var hasAnyContraindications: Bool {
        drugs.contains { !$0.contraindications.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text("Drug").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                Text("Dose / Route").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                if hasAnyContraindications {
                    Text("CI").fontWeight(.bold).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color(.tertiarySystemBackground))

            Divider()

            // Drug rows
            ForEach(drugs) { drug in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top) {
                        Text(drug.name)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(drug.dose)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(drug.route)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if hasAnyContraindications {
                            if !drug.contraindications.isEmpty {
                                SectionContentView.formattedText(drug.contraindications)
                                    .font(.caption2)
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        if !drug.notes.isEmpty {
                            Image(systemName: expandedDrugs.contains(drug.id)
                                  ? "chevron.up" : "info.circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !drug.notes.isEmpty {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedDrugs.contains(drug.id) {
                                    expandedDrugs.remove(drug.id)
                                } else {
                                    expandedDrugs.insert(drug.id)
                                }
                            }
                        }
                    }

                    if expandedDrugs.contains(drug.id) && !drug.notes.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Rectangle()
                                .fill(Color.green.opacity(0.4))
                                .frame(width: 2)
                            SectionContentView.formattedText(drug.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.green.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)

                Divider()
            }
        }
        .font(.footnote)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Image Gallery with tap-to-zoom

struct ImageGalleryView: View {
    let images: [ImageEntry]
    @State private var selectedImage: ImageEntry?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(images) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Image(entry.assetName)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .onTapGesture { selectedImage = entry }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(entry.caption)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !entry.description.isEmpty {
                        Text(entry.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedImage) { entry in
            FullScreenImageView(entry: entry)
        }
    }
}

struct FullScreenImageView: View {
    let entry: ImageEntry
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(entry.assetName)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = lastScale * value.magnification
                            }
                            .onEnded { value in
                                lastScale = max(scale, 1.0)
                                scale = max(scale, 1.0)
                                if scale == 1.0 {
                                    withAnimation { offset = .zero }
                                    lastOffset = .zero
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 3.0
                                lastScale = 3.0
                            }
                        }
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(entry.caption)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
