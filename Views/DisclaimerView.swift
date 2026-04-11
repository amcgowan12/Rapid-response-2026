import SwiftUI

struct DisclaimerView: View {
    // Owns the key directly — no Binding needed
    @AppStorage("hasAgreedToDisclaimer") private var hasAgreed: Bool = false
    @State private var checkboxTicked = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────
                VStack(spacing: 12) {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                        .padding(.top, 48)

                    Text("Rapid Response Guide")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Clinical Reference Tool")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)

                // ── Disclaimer Box ───────────────────────────────
                VStack(alignment: .leading, spacing: 16) {

                    Label("Educational Use Only", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.orange)

                    DisclaimerParagraph(
                        title: "Educational use only",
                        text: "This application is provided for educational and informational purposes only. It does not provide professional medical advice and must not be used as a substitute for clinical judgment or institutional protocols."
                    )
                    DisclaimerParagraph(
                        title: "No professional advice",
                        text: "Nothing in this app should be considered professional medical advice. Always consult a qualified healthcare professional and follow approved local practice standards when making patient care decisions."
                    )
                    DisclaimerParagraph(
                        title: "Content may be outdated",
                        text: "Drug doses, protocols, and guidelines change over time. Always verify information against current institutional policies, pharmacists, and up-to-date references."
                    )
                    DisclaimerParagraph(
                        title: "No liability",
                        text: "To the maximum extent permitted by law, the developers are not liable for any damages arising from use of this application, including direct, indirect, incidental, or consequential damages."
                    )
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                // ── Checkbox ─────────────────────────────────────
                Button {
                    checkboxTicked.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: checkboxTicked ? "checkmark.square.fill" : "square")
                            .font(.title2)
                            .foregroundColor(checkboxTicked ? .green : .secondary)
                            .offset(x: shakeOffset)

                        Text(
                            "By using this app, I agree to these terms of use. I understand it is for \(Text("educational purposes only").fontWeight(.semibold)) and is not a substitute for clinical judgment, professional advice, or institutional protocols."
                        )
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .buttonStyle(.plain)

                // ── Agree Button ──────────────────────────────────
                Button {
                    if checkboxTicked {
                        // Write directly to AppStorage — no animation wrapping
                        hasAgreed = true
                    } else {
                        triggerShake()
                    }
                } label: {
                    Text("I Agree & Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(checkboxTicked ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)

            } // end VStack
        } // end ScrollView
        .background(Color(.systemGroupedBackground))
    } // end body

    private func triggerShake() {
        let steps: [CGFloat] = [-8, 8, -6, 6, -4, 4, 0]
        for (i, offset) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }

} // end DisclaimerView


// ── Disclaimer Paragraph ──────────────────────────────────
private struct DisclaimerParagraph: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


// ── Preview ───────────────────────────────────────────────
#Preview {
    DisclaimerView()
}
