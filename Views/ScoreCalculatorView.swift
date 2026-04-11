import SwiftUI

struct ScoreCalculatorView: View {
    let calculator: ScoreCalculator
    @State private var selectedIndices: Set<Int> = []
    @State private var showShareSheet = false

    private var totalScore: Int {
        selectedIndices.reduce(0) { $0 + calculator.criteria[$1].points }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Subtitle banner
                Text(calculator.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                // Score display
                scoreCard

                // Criteria checklist
                criteriaCard

                // Risk stratification table
                riskTable

                if let linkTitle = calculator.externalLinkTitle,
                   let linkURL = calculator.externalLinkURL,
                   let url = URL(string: linkURL) {
                    Link(destination: url) {
                        Label(linkTitle, systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                // Footnotes
                if !calculator.footnotes.isEmpty {
                    FootnotesCard(footnotes: calculator.footnotes)
                }
            }
            .padding()
        }
        .navigationTitle(calculator.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share calculator")
                .accessibilityHint("Share the current score and selected criteria")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { selectedIndices.removeAll() }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(selectedIndices.isEmpty)
                .accessibilityLabel("Reset calculator")
                .accessibilityHint("Clear all selected criteria")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [calculator.shareText(
                selectedIndices: selectedIndices,
                totalScore: totalScore
            )])
        }
        .background(Color.rrPageBackground)
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 8) {
            Text("\(totalScore)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
                .contentTransition(.numericText())
                .animation(.snappy, value: totalScore)

            Text("points")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let category = calculator.riskCategory(for: totalScore) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(category.isHighlighted ? .red : .primary)
                    .multilineTextAlignment(.center)

                Text("30-day mortality: \(category.mortality)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                SectionContentView.formattedText(category.recommendation)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(scoreColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var scoreColor: Color {
        if let cat = calculator.riskCategory(for: totalScore) {
            return cat.isHighlighted ? .red : .teal
        }
        return .teal
    }

    // MARK: - Criteria Checklist

    private var criteriaCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Criteria")
                    .font(.headline)
                Spacer()
                Text("Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.rrSectionBackground)

            Divider()

            ForEach(Array(calculator.criteria.enumerated()), id: \.offset) { index, criterion in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy) {
                        if selectedIndices.contains(index) {
                            selectedIndices.remove(index)
                        } else {
                            selectedIndices.insert(index)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedIndices.contains(index)
                              ? "checkmark.circle.fill"
                              : "circle")
                            .foregroundColor(selectedIndices.contains(index)
                                             ? .teal : .secondary)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(criterion.label)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            if !criterion.detail.isEmpty {
                                Text(criterion.detail)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Text("+\(criterion.points)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedIndices.contains(index)
                                             ? .teal : .secondary)
                            .frame(minWidth: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(selectedIndices.contains(index)
                                ? Color.teal.opacity(0.06) : Color.clear)
                }
                .buttonStyle(.plain)

                if index < calculator.criteria.count - 1 {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.teal.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Risk Stratification Table

    private var riskTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Risk Class")
                    .font(.caption2).fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("30-Day Mortality")
                    .font(.caption2).fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.rrSectionBackground)

            Divider()

            ForEach(calculator.riskCategories, id: \.name) { cat in
                let isActive = cat.range.contains(totalScore)
                HStack {
                    Text(cat.name)
                        .font(.footnote)
                        .fontWeight(isActive ? .bold : .regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(cat.mortality)
                        .font(.footnote)
                        .fontWeight(isActive ? .bold : .regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(isActive
                            ? (cat.isHighlighted ? Color.red.opacity(0.1) : Color.teal.opacity(0.1))
                            : Color.clear)

                Divider()
            }
        }
        .background(Color.rrNeutralCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.teal.opacity(0.2), lineWidth: 1)
        )
    }
}
