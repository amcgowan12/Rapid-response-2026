import SwiftUI

struct ConversionTableDetailView: View {
    let table: ConversionTable
    @State private var showShareSheet = false
    @State private var medicationSortMode: MedicationSortMode = .alphabetical
    @State private var searchText = ""

    private var isAbbreviationsTable: Bool {
        table.title == "Abbreviations"
    }

    // Available width inside the VStack (.padding() = 16pt each side)
    private var tableContentWidth: CGFloat {
        UIScreen.main.bounds.width - 32
    }

    // For wide tables (many columns) allow horizontal scrolling; for narrow tables fill the screen.
    private var tableWidth: CGFloat {
        let minColWidth: CGFloat = table.columns.count > 5 ? 160 : 100
        let minNeeded = CGFloat(table.columns.count) * minColWidth
        return max(tableContentWidth, minNeeded)
    }

    private var displayedRows: [ConversionRow] {
        let baseRows: [ConversionRow]

        if let medicationEntries = table.medicationEntries {
            let sortedEntries: [MedicationReferenceEntry]
            switch medicationSortMode {
            case .alphabetical:
                sortedEntries = medicationEntries.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            case .medicationClass:
                sortedEntries = medicationEntries.sorted {
                    if $0.medicationClass == $1.medicationClass {
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                    return $0.medicationClass.localizedCaseInsensitiveCompare($1.medicationClass) == .orderedAscending
                }
            }

            baseRows = sortedEntries.map(\.row)
        } else {
            baseRows = table.rows
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isAbbreviationsTable, !query.isEmpty else { return baseRows }

        return baseRows.filter { row in
            row.cells.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Subtitle banner
                Text(table.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                if table.medicationEntries != nil {
                    Picker("Medication Sort", selection: $medicationSortMode) {
                        ForEach(MedicationSortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if isAbbreviationsTable {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)

                            TextField("Search abbreviations, meanings, or notes", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.rrNeutralCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
                        )

                        if displayedRows.isEmpty {
                            Text("No abbreviation matches.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                }

                // Size the table to fill available width for narrow column counts,
                // or scroll horizontally when more space is needed.
                ScrollView(.horizontal, showsIndicators: tableWidth > tableContentWidth) {
                    ConversionTableCard(columns: table.columns, rows: displayedRows)
                        .frame(width: tableWidth, alignment: .leading)
                }

                // Key principles / footnotes
                if !table.footnotes.isEmpty {
                    FootnotesCard(footnotes: table.footnotes)
                }
            }
            .padding()
        }
        .navigationTitle(table.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share table")
                .accessibilityHint("Share this conversion table as text")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [table.shareText])
        }
        .background(Color.rrPageBackground)
    }
}

// MARK: - Conversion Table Card

struct ConversionTableCard: View {
    let columns: [String]
    let rows: [ConversionRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header row
            HStack(alignment: .top) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    Text(column)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.rrEmphasisBackground)

            Divider()

            // Data rows
            ForEach(rows) { row in
                HStack(alignment: .top) {
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                        SectionContentView.formattedText(cell)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(row.isHighlighted ? Color.red.opacity(0.06) : Color.clear)

                Divider()
            }
        }
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.rrEmphasisBackground, lineWidth: 1)
        )
    }
}

// MARK: - Footnotes Card

struct FootnotesCard: View {
    let footnotes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 4)
                    .padding(.vertical, 6)
                    .padding(.leading, 8)

                Text("Key Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 10)

                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.rrEmphasisBackground)

            // Bullet points
            VStack(alignment: .leading, spacing: 8) {
                ForEach(footnotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        SectionContentView.formattedText(note)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(Color.rrSectionBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}
