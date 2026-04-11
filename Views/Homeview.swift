import SwiftUI

struct HomeView: View {
    @State private var mode: ContentMode = .condition
    @State private var searchText = ""
    @State private var expandedSystems: Set<String> = []
    private var loader = DataLoader.shared
    private var favorites = FavoritesManager.shared

    enum ContentMode: String, CaseIterable {
        case condition = "By Condition"
        case symptom   = "By Symptom"
        case tools     = "Tools"
    }

    private struct TopicSearchResult: Identifiable {
        let id: String
        let topic: Topic
        let system: OrganSystem
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearchingGlobally: Bool {
        !trimmedSearchText.isEmpty
    }

    var activeSystems: [OrganSystem] {
        guard mode != .tools else { return [] }
        let systems = mode == .condition
            ? loader.conditionSystems
            : loader.symptomSystems
        if trimmedSearchText.isEmpty { return systems }
        return systems.compactMap { system in
            let matched = system.topics.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedSearchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(trimmedSearchText)
            }
            guard !matched.isEmpty else { return nil }
            return OrganSystem(name: system.name, icon: system.icon,
                               color: system.color, topics: matched)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 18) {
                        Picker("Mode", selection: $mode) {
                            ForEach(ContentMode.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)

                    }
                    .padding(.vertical, 2)
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.rrSectionBackground, Color.rrNeutralCard],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.rrEmphasisBackground, lineWidth: 1)
                            )
                    )
                }

                if isSearchingGlobally {
                    globalSearchSections
                } else if mode == .tools {
                    ToolsListView()
                } else if !loader.isLoaded {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(activeSystems) { system in
                        Section {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedSystems.contains(system.name) },
                                    set: { isExpanded in
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if isExpanded {
                                            expandedSystems.insert(system.name)
                                        } else {
                                            expandedSystems.remove(system.name)
                                        }
                                    }
                                )
                            ) {
                                ForEach(system.topics) { topic in
                                    NavigationLink(destination: TopicDetailView(topic: destinationTopic(for: topic))) {
                                        TopicRow(topic: topic, color: system.color)
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(system.name, systemImage: system.icon)
                                        .foregroundColor(system.color)
                                        .font(.headline)
                                    if !expandedSystems.contains(system.name) {
                                        Text(system.topics.map(\.title).joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                            .transition(.opacity)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(Color.rrPageBackground)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("For educational use only")
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.rrDarkAccentText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.rrSectionBackground)
                    .clipShape(Capsule())
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: FavoritesView()) {
                        Image(systemName: favorites.favoriteTopics.isEmpty
                              ? "bookmark"
                              : "bookmark.fill")
                    }
                    .accessibilityLabel("Favorites")
                    .accessibilityHint("Open saved topics")
                }
            }
            .searchable(text: $searchText, prompt: "Search topics and tools...")
            .onChange(of: searchText) {
                syncExpandedSystems()
            }
            .animation(.easeInOut(duration: 0.2), value: mode)
            .onChange(of: mode) {
                UISelectionFeedbackGenerator().selectionChanged()
                syncExpandedSystems()
            }
            .onChange(of: loader.isLoaded) {
                syncExpandedSystems()
            }
            .onAppear { loader.loadIfNeeded() }
        }
    }

    private func syncExpandedSystems() {
        guard loader.isLoaded else {
            expandedSystems = []
            return
        }

        if !trimmedSearchText.isEmpty || mode == .symptom {
            expandedSystems = Set(activeSystems.map(\.name))
        } else {
            expandedSystems = []
        }
    }

    private func destinationTopic(for topic: Topic) -> Topic {
        return topic
    }

    private var navigationTitle: String {
        switch mode {
        case .condition:
            return "Rapid Response"
        case .symptom:
            return "By Symptom"
        case .tools:
            return "Tools"
        }
    }

    @ViewBuilder
    private var globalSearchSections: some View {
        if !loader.isLoaded {
            Section {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        } else {
            if !globalConditionResults.isEmpty {
                Section {
                    ForEach(globalConditionResults) { result in
                        NavigationLink(destination: TopicDetailView(topic: result.topic)) {
                            TopicRow(topic: result.topic, color: result.system.color, context: result.system.name)
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "Conditions", subtitle: "Condition topics", systemImage: "cross.case", color: .red)
                }
            }

            if !globalSymptomResults.isEmpty {
                Section {
                    ForEach(globalSymptomResults) { result in
                        NavigationLink(destination: TopicDetailView(topic: destinationTopic(for: result.topic))) {
                            TopicRow(topic: result.topic, color: result.system.color, context: result.system.name)
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "Symptoms", subtitle: "Presenting complaints", systemImage: "waveform.path.ecg", color: .orange)
                }
            }

            if !globalConversionResults.isEmpty {
                Section {
                    ForEach(globalConversionResults) { tool in
                        NavigationLink(destination: ConversionTableDetailView(table: tool)) {
                            ToolRow(tool: tool)
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "Conversion Tables", subtitle: "Dose and therapy references", systemImage: "arrow.left.arrow.right", color: .teal)
                }
            }

            if !globalScoreResults.isEmpty {
                Section {
                    ForEach(globalScoreResults) { calculator in
                        NavigationLink(destination: ScoreCalculatorView(calculator: calculator)) {
                            ScoreRow(calculator: calculator)
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "Scoring Tools", subtitle: "Risk calculators and scores", systemImage: "number.circle", color: .teal)
                }
            }

            if !globalInfoPageResults.isEmpty {
                Section {
                    ForEach(globalInfoPageResults) { page in
                        NavigationLink(destination: InfoPageView(page: page)) {
                            InfoPageRow(page: page)
                        }
                    }
                } header: {
                    SearchSectionHeader(title: "App Pages", subtitle: "Privacy, support, and help", systemImage: "doc.text.magnifyingglass", color: .indigo)
                }
            }

            if !hasGlobalResults {
                Section {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term.")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var globalConditionResults: [TopicSearchResult] {
        topicResults(in: loader.conditionSystems, prefix: "condition")
    }

    private var globalSymptomResults: [TopicSearchResult] {
        topicResults(in: loader.symptomSystems, prefix: "symptom")
    }

    private var globalConversionResults: [ConversionTable] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }

        return ConversionTable.allTools.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private var globalScoreResults: [ScoreCalculator] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }

        return ScoreCalculator.allScoreCalculators.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private var globalInfoPageResults: [InfoPage] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }

        return InfoPage.allPages.filter { page in
            page.title.localizedCaseInsensitiveContains(query) ||
            page.subtitle.localizedCaseInsensitiveContains(query) ||
            page.sections.contains { section in
                section.title.localizedCaseInsensitiveContains(query) ||
                section.items.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }

    private var hasGlobalResults: Bool {
        (!globalConditionResults.isEmpty ||
        !globalSymptomResults.isEmpty ||
        !globalConversionResults.isEmpty ||
        !globalScoreResults.isEmpty ||
        !globalInfoPageResults.isEmpty)
    }

    private func topicResults(in systems: [OrganSystem], prefix: String) -> [TopicSearchResult] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }

        return systems.flatMap { system in
            system.topics.compactMap { topic in
                guard
                    topic.title.localizedCaseInsensitiveContains(query) ||
                    topic.subtitle.localizedCaseInsensitiveContains(query)
                else {
                    return nil
                }

                return TopicSearchResult(
                    id: "\(prefix)-\(system.name)-\(topic.title)",
                    topic: topic,
                    system: system
                )
            }
        }
    }
}  // ← HomeView closes here


// ── TopicRow moved OUTSIDE HomeView ──────────────────
struct TopicRow: View {
    let topic: Topic
    let color: Color
    var context: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(topic.title)
                .font(.body)
                .fontWeight(.semibold)

            Text(topic.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let context {
                Text(context)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }
}

private struct SearchSectionHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: systemImage)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .textCase(nil)
        .padding(.top, 4)
    }
}
