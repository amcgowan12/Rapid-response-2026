import SwiftUI

struct HomeView: View {
    @State private var mode: ContentMode = .condition
    @State private var searchText = ""
    @State private var selectedSystem: OrganSystem? = nil
    private var loader = DataLoader.shared
    private var favorites = FavoritesManager.shared

    enum ContentMode: String, CaseIterable {
        case condition = "By Condition"
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
        if trimmedSearchText.isEmpty { return loader.conditionSystems }
        return loader.conditionSystems.compactMap { system in
            let matched = system.topics.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedSearchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(trimmedSearchText)
            }
            guard !matched.isEmpty else { return nil }
            return OrganSystem(name: system.name, icon: system.icon,
                               color: system.color, topics: matched)
        }
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

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
                    Section {
                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            ForEach(activeSystems) { system in
                                Button {
                                    selectedSystem = system
                                } label: {
                                    SystemGridCell(system: system)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .scrollContentBackground(.hidden)
            .background(Color.rrPageBackground)
            .navigationDestination(isPresented: Binding(
                get: { selectedSystem != nil },
                set: { if !$0 { selectedSystem = nil } }
            )) {
                if let system = selectedSystem {
                    SystemTopicsView(system: system)
                }
            }
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
            .animation(.easeInOut(duration: 0.2), value: mode)
            .onChange(of: mode) {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            .onAppear { loader.loadIfNeeded() }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .condition: return "Rapid Response"
        case .tools:     return "Tools"
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

    private var globalConversionResults: [ConversionTable] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }
        return ConversionTable.allTools.filter {
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
        !globalConditionResults.isEmpty ||
        !globalConversionResults.isEmpty ||
        !globalInfoPageResults.isEmpty
    }

    private func topicResults(in systems: [OrganSystem], prefix: String) -> [TopicSearchResult] {
        let query = trimmedSearchText
        guard !query.isEmpty else { return [] }
        return systems.flatMap { system in
            system.topics.compactMap { topic in
                guard
                    topic.title.localizedCaseInsensitiveContains(query) ||
                    topic.subtitle.localizedCaseInsensitiveContains(query)
                else { return nil }
                return TopicSearchResult(
                    id: "\(prefix)-\(system.name)-\(topic.title)",
                    topic: topic,
                    system: system
                )
            }
        }
    }
}

// MARK: - System Grid Cell

struct SystemGridCell: View {
    let system: OrganSystem

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(system.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                if system.icon == "custom.liver" {
                    LiverShape()
                        .fill(system.color)
                        .frame(width: 36, height: 30)
                } else if system.icon == "custom.kidneys" {
                    KidneysShape()
                        .fill(system.color)
                        .frame(width: 38, height: 28)
                } else {
                    Image(systemName: system.icon)
                        .font(.title2)
                        .foregroundColor(system.color)
                }
            }

            Text(system.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.rrSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
    }
}

// MARK: - Kidneys Shape

/// Two kidney bean shapes side by side, medial hilum notch facing inward.
struct KidneysShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Each kidney occupies roughly half the width with a small gap in the middle.
        // Left kidney (from viewer's perspective = anatomical right — sits slightly higher)
        let lx: CGFloat = 0        // left edge of left kidney
        let lw: CGFloat = w * 0.44 // width of each kidney
        let ly: CGFloat = 0        // top of left kidney (higher)
        let lh: CGFloat = h        // full height

        path.addPath(kidneyPath(x: lx, y: ly, kw: lw, kh: lh, hilumOnRight: true))

        // Right kidney (anatomical left — sits slightly lower)
        let rx: CGFloat = w * 0.56
        let ry: CGFloat = h * 0.08

        path.addPath(kidneyPath(x: rx, y: ry, kw: lw, kh: lh * 0.92, hilumOnRight: false))

        return path
    }

    /// Single kidney bean. `hilumOnRight` true = concavity on right side (faces the spine).
    private func kidneyPath(x: CGFloat, y: CGFloat, kw: CGFloat, kh: CGFloat, hilumOnRight: Bool) -> Path {
        var p = Path()

        if hilumOnRight {
            // Smooth outer (left) edge
            p.move(to: CGPoint(x: x + kw * 0.50, y: y))
            p.addCurve(
                to: CGPoint(x: x + kw * 0.50, y: y + kh),
                control1: CGPoint(x: x - kw * 0.30, y: y),
                control2: CGPoint(x: x - kw * 0.30, y: y + kh)
            )
            // Inner (right) edge with hilum notch
            p.addCurve(
                to: CGPoint(x: x + kw * 0.85, y: y + kh * 0.65),
                control1: CGPoint(x: x + kw * 0.90, y: y + kh),
                control2: CGPoint(x: x + kw * 1.05, y: y + kh * 0.80)
            )
            // Hilum indent
            p.addCurve(
                to: CGPoint(x: x + kw * 0.85, y: y + kh * 0.35),
                control1: CGPoint(x: x + kw * 0.60, y: y + kh * 0.55),
                control2: CGPoint(x: x + kw * 0.60, y: y + kh * 0.45)
            )
            p.addCurve(
                to: CGPoint(x: x + kw * 0.50, y: y),
                control1: CGPoint(x: x + kw * 1.05, y: y + kh * 0.20),
                control2: CGPoint(x: x + kw * 0.90, y: y)
            )
        } else {
            // Smooth outer (right) edge
            p.move(to: CGPoint(x: x + kw * 0.50, y: y))
            p.addCurve(
                to: CGPoint(x: x + kw * 0.50, y: y + kh),
                control1: CGPoint(x: x + kw * 1.30, y: y),
                control2: CGPoint(x: x + kw * 1.30, y: y + kh)
            )
            // Inner (left) edge with hilum notch
            p.addCurve(
                to: CGPoint(x: x + kw * 0.15, y: y + kh * 0.65),
                control1: CGPoint(x: x + kw * 0.10, y: y + kh),
                control2: CGPoint(x: x - kw * 0.05, y: y + kh * 0.80)
            )
            // Hilum indent
            p.addCurve(
                to: CGPoint(x: x + kw * 0.15, y: y + kh * 0.35),
                control1: CGPoint(x: x + kw * 0.40, y: y + kh * 0.55),
                control2: CGPoint(x: x + kw * 0.40, y: y + kh * 0.45)
            )
            p.addCurve(
                to: CGPoint(x: x + kw * 0.50, y: y),
                control1: CGPoint(x: x - kw * 0.05, y: y + kh * 0.20),
                control2: CGPoint(x: x + kw * 0.10, y: y)
            )
        }

        p.closeSubpath()
        return p
    }
}

// MARK: - Liver Shape

struct LiverShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Main liver body — clockwise from far-left tip of right lobe
        path.move(to: CGPoint(x: w * 0.02, y: h * 0.50))

        // Left side up to top-left of right lobe
        path.addCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.04),
            control1: CGPoint(x: w * 0.00, y: h * 0.24),
            control2: CGPoint(x: w * 0.09, y: h * 0.04)
        )

        // Top of right lobe sweeping right toward fissure
        path.addCurve(
            to: CGPoint(x: w * 0.49, y: h * 0.06),
            control1: CGPoint(x: w * 0.36, y: h * 0.00),
            control2: CGPoint(x: w * 0.44, y: h * 0.03)
        )

        // Deep fissure — down into the interlobar notch
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.36),
            control1: CGPoint(x: w * 0.51, y: h * 0.14),
            control2: CGPoint(x: w * 0.52, y: h * 0.28)
        )

        // Back up out of fissure to base of left lobe
        path.addCurve(
            to: CGPoint(x: w * 0.59, y: h * 0.08),
            control1: CGPoint(x: w * 0.52, y: h * 0.22),
            control2: CGPoint(x: w * 0.55, y: h * 0.08)
        )

        // Top of left lobe — flatter, more rectangular
        path.addCurve(
            to: CGPoint(x: w * 0.96, y: h * 0.08),
            control1: CGPoint(x: w * 0.74, y: h * 0.02),
            control2: CGPoint(x: w * 0.90, y: h * 0.03)
        )

        // Right side of left lobe going down
        path.addCurve(
            to: CGPoint(x: w * 0.96, y: h * 0.52),
            control1: CGPoint(x: w * 1.02, y: h * 0.20),
            control2: CGPoint(x: w * 1.02, y: h * 0.42)
        )

        // Bottom of left lobe — left lobe ends here, right lobe continues below
        path.addCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.58),
            control1: CGPoint(x: w * 0.98, y: h * 0.62),
            control2: CGPoint(x: w * 0.80, y: h * 0.62)
        )

        // Bottom of right lobe sweeping down and left
        path.addCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.82),
            control1: CGPoint(x: w * 0.48, y: h * 0.60),
            control2: CGPoint(x: w * 0.46, y: h * 0.82)
        )

        // Gallbladder fossa — concave notch before gallbladder
        path.addCurve(
            to: CGPoint(x: w * 0.20, y: h * 0.76),
            control1: CGPoint(x: w * 0.29, y: h * 0.90),
            control2: CGPoint(x: w * 0.22, y: h * 0.86)
        )

        // Bottom-left back up to far-left tip
        path.addCurve(
            to: CGPoint(x: w * 0.02, y: h * 0.50),
            control1: CGPoint(x: w * 0.10, y: h * 0.78),
            control2: CGPoint(x: w * 0.02, y: h * 0.66)
        )

        path.closeSubpath()

        // Gallbladder — small oval below the fossa
        path.addEllipse(in: CGRect(
            x: w * 0.15,
            y: h * 0.76,
            width: w * 0.18,
            height: h * 0.22
        ))

        return path
    }
}

// MARK: - System Topics View

struct SystemTopicsView: View {
    let system: OrganSystem

    var body: some View {
        List {
            ForEach(system.topics) { topic in
                NavigationLink(destination: TopicDetailView(topic: topic)) {
                    TopicRow(topic: topic, color: system.color)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.rrPageBackground)
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Topic Row

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

// MARK: - Search Section Header

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
