import AudioToolbox
import MessageUI
import SwiftUI
import Combine

struct TopicDetailView: View {
    let topic: Topic
    @State private var expandedSections: Set<UUID> = []
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var isSeeAlsoExpanded = false
    @State private var topicPresentationMode: TopicPresentationMode = .guide
    @State private var completedChecklistItems: Set<String> = []
    @State private var commentText = ""
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    @State private var cardiacArrestTimerSeconds = 0
    @State private var cardiacArrestTimerIsRunning = false
    @State private var cardiacArrestTimerIsMinimized = false
    @State private var epiTimerSeconds = 0
    @State private var epiDoseCount = 0
    @State private var medCounts: [String: Int] = [:]
    @StateObject private var metronome = MetronomeController()
    var favorites = FavoritesManager.shared
    private let cardiacArrestTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    /// Other ACLS meds tracked with tap-to-count buttons (epi & shock have dedicated buttons).
    private let aclsMedButtons = ["Amiodarone", "Lidocaine", "Bicarb", "Calcium", "Mag"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.rrPageBackground
                .ignoresSafeArea()

            topicBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    topicHeader

                    if supportsChecklistPresentation && topicPresentationMode == .checklist {
                        checklistView
                    } else {
                        ForEach(Array(topic.sections.enumerated()), id: \.element.id) { index, section in
                            let isSearching = !searchText.isEmpty
                            let isMatch = matchingSectionIDs.contains(section.id)
                            SectionCard(
                                section: section,
                                isFirstSection: index == 0,
                                isExpanded: expandedSections.contains(section.id) || (isSearching && isMatch),
                                onTap: { toggleSection(section.id) },
                                currentTopicTitle: topic.title,
                                drugLookup: topicDrugLookup
                            )
                            .opacity(isSearching && !isMatch ? 0.35 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
                        }

                        if !searchText.isEmpty && matchingSectionIDs.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                                .padding(.top, 8)
                        }
                    }

                    if !seeAlsoTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSeeAlsoExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text("See Also")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.rrDarkAccentText)
                                        .textCase(.uppercase)

                                    Spacer()

                                    Image(systemName: isSeeAlsoExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.rrDarkAccentText)
                                }
                            }
                            .buttonStyle(.plain)

                            if isSeeAlsoExpanded {
                                FlowLayout(spacing: 8) {
                                    ForEach(seeAlsoTopics, id: \.title) { related in
                                        NavigationLink(destination: TopicDetailView(topic: related)) {
                                            Text(related.title)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.rrDarkAccentText)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.rrSectionBackground)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.rrNeutralCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
                        )
                        .padding(.top, 8)
                    }

                    commentsSection
                }
                .padding()
            }

            if showsCardiacArrestTimer {
                VStack {
                    HStack {
                        floatingCardiacArrestTimer
                        if cardiacArrestTimerIsMinimized {
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search sections")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share topic")
                    .accessibilityHint("Share this topic as text")

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        favorites.toggle(topic.title)
                    } label: {
                        Image(systemName: favorites.isFavorite(topic.title)
                              ? "bookmark.fill"
                              : "bookmark")
                            .foregroundColor(favorites.isFavorite(topic.title)
                                             ? .accentColor : .secondary)
                    }
                    .accessibilityLabel(favorites.isFavorite(topic.title) ? "Remove bookmark" : "Bookmark topic")
                    .accessibilityHint("Save this topic to favorites")

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if expandedSections.count == topic.sections.count {
                            expandedSections.removeAll()
                        } else {
                            expandedSections = Set(topic.sections.map { $0.id })
                        }
                    } label: {
                        Image(systemName: expandedSections.count == topic.sections.count
                              ? "rectangle.compress.vertical"
                              : "rectangle.expand.vertical")
                    }
                    .accessibilityLabel(expandedSections.count == topic.sections.count ? "Collapse all sections" : "Expand all sections")
                    .accessibilityHint("Toggle all topic sections")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [topic.shareText])
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                recipients: ["amcgowan12@rrtxapp.com"],
                subject: "Rapid Response Feedback: \(topic.title)",
                body: formattedCommentBody,
                onFinish: { result, _ in
                    showMailComposer = false
                    if result == .sent {
                        commentText = ""
                    }
                }
            )
        }
        .alert("Mail is unavailable", isPresented: $showMailUnavailableAlert) {
            Button("Open Mail App") {
                openMailFallback()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This device is not configured for in-app email. You can continue in the Mail app.")
        }
        .onAppear {
            // Auto-expand the first section
            if let first = topic.sections.first {
                expandedSections.insert(first.id)
            }

            if showsCardiacArrestTimer {
                resetCardiacArrestTracking()
            }
        }
        .onDisappear {
            cardiacArrestTimerIsRunning = false
            cardiacArrestTimerIsMinimized = false
            metronome.stop()
        }
        .onReceive(cardiacArrestTimer) { _ in
            guard showsCardiacArrestTimer, cardiacArrestTimerIsRunning else { return }
            cardiacArrestTimerSeconds += 1
            epiTimerSeconds += 1
        }
    }

    @ViewBuilder
    private var topicBackground: some View {
        if let assetName = topicBackgroundAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .opacity(0.12)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var topicBackgroundAssetName: String? {
        switch topic.title {
        case "AFib / Flutter with RVR":
            return "Afib RVR Background"
        default:
            return nil
        }
    }

    /// Collects related topics: cross-linked topics + siblings from the same system
    private var topicDrugLookup: [String: DrugEntry] {
        var lookup: [String: DrugEntry] = [:]
        for section in topic.sections {
            if case .drugTable(let drugs) = section.content {
                for drug in drugs {
                    let key = drug.name.lowercased()
                    lookup[key] = drug
                    // Also index the name without parenthetical so "Normal saline" matches "Normal saline (0.9% NaCl)"
                    if let parenIdx = drug.name.firstIndex(of: "(") {
                        let base = drug.name[..<parenIdx]
                            .trimmingCharacters(in: .whitespaces)
                            .lowercased()
                        if !base.isEmpty && lookup[base] == nil {
                            lookup[base] = drug
                        }
                    }
                }
            }
        }
        return lookup
    }

    private var seeAlsoTopics: [Topic] {
        var result: [Topic] = []
        var seen = Set<String>()
        seen.insert(topic.title)

        // 1. Cross-linked topics from keyValue topicLinks
        for title in topic.relatedTopicTitles {
            if !seen.contains(title), let t = SectionContentView.findTopic(titled: title) {
                seen.insert(title)
                result.append(t)
            }
        }

        // 2. Sibling topics from the same organ/symptom system
        let allSystems: [OrganSystem] = OrganSystem.allSystems
        for system in allSystems {
            if system.topics.contains(where: { $0.title == topic.title }) {
                for sibling in system.topics where !seen.contains(sibling.title) {
                    seen.insert(sibling.title)
                    result.append(sibling)
                }
            }
        }

        return result
    }

    private func toggleSection(_ id: UUID) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }

    private var matchingSectionIDs: Set<UUID> {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return Set(topic.sections.compactMap { section -> UUID? in
            if section.title.lowercased().contains(query) { return section.id }
            switch section.content {
            case .bullets(let items), .steps(let items):
                return items.contains(where: { $0.lowercased().contains(query) }) ? section.id : nil
            case .keyValue(let pairs):
                return pairs.contains(where: {
                    $0.key.lowercased().contains(query) || $0.value.lowercased().contains(query)
                }) ? section.id : nil
            case .drugTable(let drugs):
                return drugs.contains(where: {
                    $0.name.lowercased().contains(query) ||
                    $0.dose.lowercased().contains(query) ||
                    $0.notes.lowercased().contains(query)
                }) ? section.id : nil
            case .imageGallery(let images):
                return images.contains(where: {
                    $0.caption.lowercased().contains(query) || $0.description.lowercased().contains(query)
                }) ? section.id : nil
            }
        })
    }

    private var topicHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if supportsChecklistPresentation {
                Picker("View", selection: $topicPresentationMode) {
                    ForEach(TopicPresentationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } else if !topic.subtitle.isEmpty {
                Text(topic.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.rrSectionBackground, Color.rrNeutralCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
    }

    private var supportsChecklistPresentation: Bool {
        !checklistItems.isEmpty
    }

    private var showsCardiacArrestTimer: Bool {
        topic.title == "Cardiac Arrest"
    }

    private var floatingCardiacArrestTimer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Code Timer")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.rrDarkAccentText)
                        .textCase(.uppercase)

                    Text(formattedCardiacArrestTime)
                        .font(.system(size: cardiacArrestTimerIsMinimized ? 20 : 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }

                if cardiacArrestTimerIsMinimized && epiDoseCount > 0 {
                    Text("EPI \(formattedEpiTime) · ×\(epiDoseCount)")
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(epiIntervalColor)
                }

                Spacer(minLength: 8)

                if !cardiacArrestTimerIsMinimized {
                    Button(cardiacArrestTimerIsRunning ? "Stop" : "Start") {
                        cardiacArrestTimerIsRunning.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(cardiacArrestTimerIsRunning ? .red : .accentColor)

                    Button("Reset") {
                        resetCardiacArrestTracking()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button {
                    cardiacArrestTimerIsMinimized.toggle()
                } label: {
                    Image(systemName: cardiacArrestTimerIsMinimized ? "arrow.up.left.and.arrow.down.right" : "minus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.rrDarkAccentText)
                        .frame(width: 24, height: 24)
                        .background(Color.rrSectionBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if !cardiacArrestTimerIsMinimized {
                epiTrackerCard

                medButtonGrid

                metronomeCard
            }
        }
        .padding(10)
        .frame(maxWidth: cardiacArrestTimerIsMinimized ? nil : .infinity, alignment: .leading)
        .background(Color.rrNeutralCard.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    /// EPI interval timer: elapsed since last dose (color-coded to the q3–5 min window) + dose count.
    private var epiTrackerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("EPI")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.rrDarkAccentText)
                Spacer()
                Text("×\(epiDoseCount)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Since last dose")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(epiDoseCount > 0 ? formattedEpiTime : "--:--")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(epiDoseCount > 0 ? epiIntervalColor : .secondary)
                }

                Spacer()

                Text(epiStatusText)
                    .font(.caption2.weight(.medium))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(epiDoseCount > 0 ? epiIntervalColor : .secondary)
            }

            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    epiDoseCount += 1
                    epiTimerSeconds = 0
                    if !cardiacArrestTimerIsRunning {
                        cardiacArrestTimerIsRunning = true
                    }
                } label: {
                    Text("EPI given")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    medCounts["Shock", default: 0] += 1
                    if !cardiacArrestTimerIsRunning {
                        cardiacArrestTimerIsRunning = true
                    }
                } label: {
                    Text("Shock ×\(medCounts["Shock", default: 0])")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .onLongPressGesture {
                    if medCounts["Shock", default: 0] > 0 {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        medCounts["Shock", default: 0] -= 1
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rrSectionBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Tap-to-count buttons for the other ACLS meds / shocks (long-press to decrement a mis-tap).
    private var medButtonGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: aclsMedButtons.count), spacing: 6) {
            ForEach(aclsMedButtons, id: \.self) { name in
                let count = medCounts[name, default: 0]
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    medCounts[name, default: 0] += 1
                } label: {
                    VStack(spacing: 2) {
                        Text(name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("×\(count)")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(count > 0 ? Color.rrDarkAccentText.opacity(0.14) : Color.rrSectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(count > 0 ? Color.rrDarkAccentText : .primary)
                .onLongPressGesture {
                    if medCounts[name, default: 0] > 0 {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        medCounts[name, default: 0] -= 1
                    }
                }
            }
        }
    }

    private var metronomeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "metronome")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.rrDarkAccentText)
                Text("CPR Metronome")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.rrDarkAccentText)
                Spacer()
                Button(metronome.isRunning ? "Stop" : "Start") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if metronome.isRunning { metronome.stop() } else { metronome.start() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(metronome.isRunning ? .red : Color.rrCheckmarkGreen)
            }

            HStack(spacing: 0) {
                Button { metronome.adjustBPM(by: -5) } label: {
                    Text("−5")
                        .font(.caption.weight(.bold))
                        .frame(width: 38, height: 32)
                        .background(Color.rrSectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { metronome.adjustBPM(by: -1) } label: {
                    Text("−1")
                        .font(.caption2.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.rrSectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)

                Spacer()

                VStack(spacing: 1) {
                    Text("\(metronome.bpm)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(metronome.isRunning ? Color.rrCheckmarkGreen : .primary)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button { metronome.adjustBPM(by: 1) } label: {
                    Text("+1")
                        .font(.caption2.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.rrSectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)

                Button { metronome.adjustBPM(by: 5) } label: {
                    Text("+5")
                        .font(.caption.weight(.bold))
                        .frame(width: 38, height: 32)
                        .background(Color.rrSectionBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.rrSectionBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resetCardiacArrestTracking() {
        cardiacArrestTimerSeconds = 0
        cardiacArrestTimerIsRunning = false
        cardiacArrestTimerIsMinimized = false
        epiTimerSeconds = 0
        epiDoseCount = 0
        medCounts = [:]
    }

    private var formattedCardiacArrestTime: String {
        formattedClock(cardiacArrestTimerSeconds)
    }

    private var formattedEpiTime: String {
        formattedClock(epiTimerSeconds)
    }

    private func formattedClock(_ totalSeconds: Int) -> String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// Gray before 3 min, green in the 3–5 min give-window, red once overdue.
    private var epiIntervalColor: Color {
        switch epiTimerSeconds {
        case ..<180: return .secondary
        case 180...300: return .green
        default: return .red
        }
    }

    private var epiStatusText: String {
        guard epiDoseCount > 0 else { return "No epi given yet" }
        switch epiTimerSeconds {
        case ..<180:
            return "Next dose in \(formattedClock(180 - epiTimerSeconds))"
        case 180...300:
            return "Due now (3–5 min window)"
        default:
            return "Overdue — give epi"
        }
    }

    private var checklistView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Checklist")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(Color.rrDarkAccentText)
                .textCase(.uppercase)

            ForEach(checklistItems, id: \.self) { item in
                Button {
                    toggleChecklistItem(item)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: completedChecklistItems.contains(item) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(
                                completedChecklistItems.contains(item)
                                ? Color.rrCheckmarkGreen
                                : Color.secondary.opacity(0.6)
                            )
                            .padding(.top, 1)

                        Text(item)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)

                if item != checklistItems.last {
                    Divider()
                        .overlay(Color.rrEmphasisBackground.opacity(0.55))
                }
            }
        }
        .padding(18)
        .background(Color.rrSectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
    }

    private var checklistItems: [String] {
        switch topic.title {
        case "Acute Respiratory Failure":
            return [
                "Assess Severity: vitals, WOB, mentation, SpO₂, ± ABG/VBG.",
                "Airway protection; prep intubation if unable to protect airway/ worsening fatigue/acidosis.",
                "sit patient up, Supplemental O₂; goal SpO₂ 92–96% (88–92% if COPD/OHS).",
                "Escalation: NC → HFNC → BiPAP → vent OR NC → BiPAP → vent(see mgmt section)",
                "Conntect to monitor, get accurate vitals. Check Tele.",
                "Chart check",
                "Labs: CBC/CMP/lactate, ABG/VBG, ±ECG +  troponin, c/f sepsis? cultures, COVID/RPP?",
                "CXR (call), CT chest? lung US?.",
                "working diagnosis + DDx?",
                "- Underlying cause: bronchodilators/steroids, Abx, diuresis, anticoagulation.",
                "HOB elevation, suctioning.",
                "Ensure DVT PPTx, aspiration precautions.",
                "Trend: O₂ needs, gases, labs, imaging.",
                "Level of care/ End RR ."
            ]
        case "Cardiac Arrest":
            return [
                "Start CPR. Get backboard under pt.",
                "Call code. Confirm code status. Place pads.",
                "Assign roles. Compressor, airway, recorder, meds, access.",
                "Check rhythm q2 min. Minimize pauses.",
                "Shock VF/pVT. Resume CPR. Get IV/IO.",
                "Give epinephrine early for PEA/asystole. Keep CPR going.",
                "Give amiodarone or lidocaine for refractory shockable rhythm.",
                "Secure airway when compressions will not be interrupted.",
                "Use waveform capnography if advanced airway is placed.",
                "Look for Hs and Ts. Treat reversible causes.",
                "Use POCUS only during rhythm checks if no extra pause.",
                "Check for ROSC after each cycle. Escalate early if needed."
            ]
        case "Sick Sinus / Tachy-Brady Syndrome":
            return [
                "Check rhythm. Decide brady vs tachy.",
                "Check stability. BP, mentation, shock, chest pain, HF.",
                "Stop nodal blockers. Look for reversible causes.",
                "Get ECG. Put on telemetry.",
                "Give atropine if symptomatic bradycardia.",
                "Start epi or dopamine if atropine fails.",
                "Place pads early if pacing may be needed.",
                "Cardiovert if unstable tachyarrhythmia.",
                "Use vagal maneuvers or rate control if stable tachycardia.",
                "Avoid antiarrhythmics if they may worsen bradycardia.",
                "Plan PPM if symptoms persist or recur.",
                "Call cardiology early if pauses, syncope, or pacing need."
            ]
        case "SVT (Supraventricular Tachycardia)":
            return [
                "Check stability. BP, mentation, chest pain, HF.",
                "Get ECG. Confirm regular narrow-complex rhythm.",
                "Place pads early if unstable or borderline.",
                "Cardiovert if unstable.",
                "Try vagal maneuvers if stable.",
                "Give adenosine if regular SVT and no contraindication.",
                "Use diltiazem or beta-blocker if adenosine fails and rhythm is still stable.",
                "Avoid AV nodal blockers in WPW or irregular wide-complex rhythm.",
                "Check BMP, Mg, ECG, and triggers.",
                "Look for precipitant. Infection, dehydration, thyroid, stimulants.",
                "Reassess rhythm after each intervention.",
                "Call cardiology early if refractory, recurrent, or unclear rhythm."
            ]
        default:
            return []
        }
    }

    private func toggleChecklistItem(_ item: String) {
        if completedChecklistItems.contains(item) {
            completedChecklistItems.remove(item)
        } else {
            completedChecklistItems.insert(item)
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.rrEmphasisBackground)
                        .frame(width: 36, height: 36)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Send Comments")
                        .font(.headline)

                    Text("Share feedback about this page.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            TextEditor(text: $commentText)
                .frame(minHeight: 140)
                .padding(10)
                .background(Color.rrSectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                sendComments()
            } label: {
                Label("Send Comments", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(18)
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
        .padding(.top, 12)
    }

    private var formattedCommentBody: String {
        """
        Topic: \(topic.title)

        Comments:
        \(commentText.trimmingCharacters(in: .whitespacesAndNewlines))
        """
    }

    private func sendComments() {
        commentText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentText.isEmpty else { return }

        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailUnavailableAlert = true
        }
    }

    private func openMailFallback() {
        guard
            let subject = "Rapid Response Feedback: \(topic.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let body = formattedCommentBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "mailto:amcgowan12@rrtxapp.com?subject=\(subject)&body=\(body)")
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}

// MARK: - Metronome

final class MetronomeController: ObservableObject {
    @Published var isRunning = false
    @Published var bpm: Int = 105

    private var timer: DispatchSourceTimer?
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)

    func start() {
        guard !isRunning else { return }
        isRunning = true
        haptic.prepare()
        schedule()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }

    func adjustBPM(by delta: Int) {
        bpm = max(60, min(180, bpm + delta))
        if isRunning { timer?.cancel(); schedule() }
    }

    private func schedule() {
        let interval = 60.0 / Double(bpm)
        let source = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        source.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(5))
        source.setEventHandler { [weak self] in
            AudioServicesPlaySystemSound(1057) // keyboard click — short, sharp
            self?.haptic.impactOccurred()
            self?.haptic.prepare()
        }
        source.resume()
        timer = source
    }

    deinit { timer?.cancel() }
}

private enum TopicPresentationMode: String, CaseIterable, Identifiable {
    case guide
    case checklist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guide:
            return "Guide"
        case .checklist:
            return "Checklist"
        }
    }
}

// MARK: - Flow Layout for wrapping chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let onFinish: (MFMailComposeResult, Error?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(recipients)
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult, Error?) -> Void

        init(onFinish: @escaping (MFMailComposeResult, Error?) -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) {
                self.onFinish(result, error)
            }
        }
    }
}
