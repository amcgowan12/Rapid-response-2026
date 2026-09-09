import SwiftUI

struct ToolsListView: View {
    var body: some View {
        Section {
            ForEach(ConversionTable.allTools) { tool in
                NavigationLink(destination: ConversionTableDetailView(table: tool)) {
                    ToolRow(tool: tool)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "Conversion Tables",
                subtitle: "Dose and therapy references",
                systemImage: "arrow.left.arrow.right",
                color: .teal
            )
        }

        Section {
            ForEach(ScoreCalculator.allScoreCalculators) { calc in
                NavigationLink(destination: ScoreCalculatorView(calculator: calc)) {
                    ScoreRow(calculator: calc)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "Scoring Tools",
                subtitle: "Risk calculators and bedside scores",
                systemImage: "number.circle",
                color: .teal
            )
        }

        Section {
            ForEach(InfoPage.howToPages) { page in
                NavigationLink(destination: InfoPageView(page: page)) {
                    InfoPageRow(page: page)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "How To",
                subtitle: "Quick procedural setup guides",
                systemImage: "cross.case.fill",
                color: .red
            )
        }

        Section {
            ForEach(InfoPage.dataAndPrivacyPages) { page in
                NavigationLink(destination: InfoPageView(page: page)) {
                    InfoPageRow(page: page)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "Data & Privacy",
                subtitle: "Policies and app data handling",
                systemImage: "lock.shield",
                color: .indigo
            )
        }

        Section {
            ForEach(InfoPage.supportPages) { page in
                NavigationLink(destination: InfoPageView(page: page)) {
                    InfoPageRow(page: page)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "Support",
                subtitle: "Help, feedback, and troubleshooting",
                systemImage: "lifepreserver",
                color: .orange
            )
        }
    }
}

struct ToolRow: View {
    let tool: ConversionTable

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: tool.icon)
                    .font(.headline)
                    .foregroundColor(.teal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

struct ScoreRow: View {
    let calculator: ScoreCalculator

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: calculator.icon)
                    .font(.headline)
                    .foregroundColor(.teal)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(calculator.title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(calculator.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

private struct ToolSectionHeader: View {
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

struct InfoPage: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let sections: [InfoPageSection]

    static let howToPages: [InfoPage] = [
        InfoPage(
            id: "io-placement",
            title: "Place an IO",
            subtitle: "Rapid intraosseous access setup and placement",
            icon: "bolt.heart",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "When to Use", items: [
                    "Use when rapid vascular access is needed and peripheral IV access is delayed or failing.",
                    "Common scenarios: cardiac arrest, profound shock, severe trauma, status epilepticus, or crashing patient."
                ]),
                InfoPageSection(title: "Preferred Sites", items: [
                    "Proximal tibia: easiest landmark and common first choice.",
                    "Proximal humerus: fastest flow in many adults if landmarks are clear.",
                    "Distal tibia: backup option when other sites are unavailable."
                ]),
                InfoPageSection(title: "How To", items: [
                    "Confirm indication, identify landmarks, clean the skin, and stabilize the extremity.",
                    "Insert the needle at 90 degrees to bone using firm pressure and the driver until loss of resistance is felt.",
                    "Remove stylet, confirm the needle is standing upright, aspirate marrow if possible, then flush hard with 10 mL saline.",
                    "Attach extension tubing, secure the line, and pressure-bag infusions if needed."
                ]),
                InfoPageSection(title: "Safety Checks", items: [
                    "Watch for extravasation, compartment syndrome, bent needle, or inability to flush.",
                    "Avoid fractured bone, overlying infection, or prior recent IO attempt at the same site."
                ])
            ]
        ),
        InfoPage(
            id: "central-line",
            title: "Place a Central Line",
            subtitle: "High-level checklist for urgent central venous access",
            icon: "lines.measurement.vertical",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Before You Start", items: [
                    "Clarify why the line is needed: vasoactive medications, poor access, large-volume resuscitation, or central venous monitoring.",
                    "Choose site based on urgency, anatomy, bleeding risk, infection risk, and operator experience."
                ]),
                InfoPageSection(title: "Setup", items: [
                    "Get full sterile barrier setup: cap, mask, sterile gown, sterile gloves, full-body drape, chlorhexidine prep, ultrasound, and line kit.",
                    "Place patient, optimize positioning, and confirm you have flushing syringes, caps, and a securement plan ready."
                ]),
                InfoPageSection(title: "How To", items: [
                    "Prep and drape widely, identify the vessel with ultrasound, and anesthetize if time and condition allow.",
                    "Cannulate under ultrasound guidance, confirm venous blood return, pass guidewire smoothly, then dilate and place the catheter.",
                    "Flush all ports, secure the line, apply sterile dressing, and confirm placement and absence of complication."
                ]),
                InfoPageSection(title: "After Placement", items: [
                    "Check for easy blood return and flushing in each lumen.",
                    "Confirm tip location per local workflow and evaluate for pneumothorax when indicated."
                ])
            ]
        ),
        InfoPage(
            id: "arterial-line",
            title: "Place an A Line",
            subtitle: "Bedside arterial line setup and troubleshooting",
            icon: "waveform.path.ecg.rectangle",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Indications", items: [
                    "Use for continuous blood pressure monitoring or repeated arterial blood gas sampling.",
                    "Common sites are radial first, then femoral if needed in unstable patients."
                ]),
                InfoPageSection(title: "Setup", items: [
                    "Assemble transducer tubing, pressure bag, flush system, sterile supplies, ultrasound if needed, and securement materials.",
                    "Level and zero the transducer at the phlebostatic axis once connected."
                ]),
                InfoPageSection(title: "How To", items: [
                    "Prep the site, position the limb, and identify the artery by palpation or ultrasound.",
                    "Advance the catheter into the artery until pulsatile blood return is obtained, thread the catheter, and connect to the flushed pressure tubing.",
                    "Secure the catheter, confirm a crisp waveform, and correlate with cuff pressure."
                ]),
                InfoPageSection(title: "Troubleshooting", items: [
                    "If waveform is damped, check tubing, kinks, air bubbles, clot, and wrist position.",
                    "Monitor for ischemia, hematoma, dislodgement, or infection."
                ])
            ]
        ),
        InfoPage(
            id: "supraglottic-airway",
            title: "Place a Supraglottic Airway",
            subtitle: "Rescue airway insertion and confirmation steps",
            icon: "lungs.fill",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "When to Use", items: [
                    "Use as a rescue airway when bag-mask ventilation is difficult or as a bridge to definitive airway management.",
                    "Choose the device size based on patient size and local equipment."
                ]),
                InfoPageSection(title: "Preparation", items: [
                    "Preoxygenate, suction the airway, position the head if feasible, and have backup airway equipment ready.",
                    "Lubricate the posterior surface of the device and fully deflate the cuff if required by the model."
                ]),
                InfoPageSection(title: "How To", items: [
                    "Open the mouth, advance the device along the hard palate until seated, and inflate the cuff to the recommended volume if applicable.",
                    "Attach bagging circuit, ventilate, and confirm chest rise, improving oxygenation, and end-tidal CO2.",
                    "Secure the device and reassess frequently for leak, displacement, or inadequate ventilation."
                ]),
                InfoPageSection(title: "Limitations", items: [
                    "Does not fully protect against aspiration.",
                    "Escalate quickly if ventilation is inadequate or airway pressures are high."
                ])
            ]
        ),
        InfoPage(
            id: "use-zoll",
            title: "Use the Zoll",
            subtitle: "Pads, rhythm checks, cardioversion, and pacing basics",
            icon: "bolt.badge.clock",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Initial Setup", items: [
                    "Turn the device on, expose the chest, place pads in the recommended position, and connect cables before you need to shock.",
                    "Confirm the monitor is showing an interpretable rhythm and that leads or pads are attached correctly."
                ]),
                InfoPageSection(title: "Defibrillation / Cardioversion", items: [
                    "For pulseless shockable rhythm, charge immediately and resume compressions while charging when appropriate.",
                    "For synchronized cardioversion, activate sync mode, confirm markers on each QRS, select energy, announce clear, and deliver the shock."
                ]),
                InfoPageSection(title: "Pacing", items: [
                    "For unstable bradycardia, place pads, start pacing mode, increase milliamps until electrical capture, then confirm mechanical capture with pulse or arterial waveform.",
                    "Provide analgesia or sedation if the patient is awake and time permits."
                ]),
                InfoPageSection(title: "Common Pitfalls", items: [
                    "Loss of sync markers before cardioversion can lead to an unsynchronized shock.",
                    "Electrical capture alone is not enough during pacing; always confirm a pulse.",
                    "If the rhythm or artifact looks wrong, check pad contact, cable connections, and patient movement."
                ])
            ]
        )
    ]

    static let dataAndPrivacyPages: [InfoPage] = [
        InfoPage(
            id: "privacy-policy",
            title: "Privacy Policy",
            subtitle: "What the app stores and what it does not collect",
            icon: "hand.raised.fill",
            accentColor: .indigo,
            sections: [
                InfoPageSection(title: "Overview", items: [
                    "This app is designed as a bedside clinical reference.",
                    "It does not require account creation to browse core content.",
                    "It is not intended to collect identifiable patient information."
                ]),
                InfoPageSection(title: "Stored On Device", items: [
                    "Bookmarks and local preferences may be stored on your device.",
                    "Disclaimer acknowledgement is stored locally so you do not need to re-confirm each launch."
                ]),
                InfoPageSection(title: "Clinical Use", items: [
                    "Do not enter protected health information unless your institutional policy explicitly allows it.",
                    "Always follow your hospital's privacy and security requirements."
                ])
            ]
        ),
        InfoPage(
            id: "terms-of-service",
            title: "Terms of Service",
            subtitle: "Conditions for using the app",
            icon: "doc.text.fill",
            accentColor: .indigo,
            sections: [
                InfoPageSection(title: "Use of App", items: [
                    "This app is provided as an educational and bedside reference tool.",
                    "It does not replace clinical judgment, supervision, or institutional protocols.",
                    "Users are responsible for verifying recommendations before applying them in patient care."
                ]),
                InfoPageSection(title: "Limitation", items: [
                    "Content may change over time and may not reflect every local workflow.",
                    "The app should not be the sole source for diagnosis or treatment decisions."
                ])
            ]
        ),
        InfoPage(
            id: "data-usage",
            title: "Data Usage",
            subtitle: "How app data is used in practice",
            icon: "externaldrive.fill",
            accentColor: .indigo,
            sections: [
                InfoPageSection(title: "Local Data", items: [
                    "Reference content is packaged for in-app use.",
                    "Favorites and interface settings are used to improve your local workflow."
                ]),
                InfoPageSection(title: "Recommended Practice", items: [
                    "Avoid placing patient-identifiable data into any free-text field.",
                    "Use approved hospital systems for charting, orders, and communication."
                ])
            ]
        )
    ]

    static let supportPages: [InfoPage] = [
        InfoPage(
            id: "contact-support",
            title: "Contact Support",
            subtitle: "Reach the app maintainer",
            icon: "envelope.fill",
            accentColor: .orange,
            sections: [
                InfoPageSection(title: "Support", items: [
                    "For questions, feedback, or urgent app issues, contact: amcgowan12@rrtxapp.com",
                    "Include the page name, issue observed, and device or iOS version when possible."
                ])
            ]
        ),
        InfoPage(
            id: "faq",
            title: "FAQ",
            subtitle: "Common questions and quick answers",
            icon: "questionmark.circle.fill",
            accentColor: .orange,
            sections: [
                InfoPageSection(title: "Common Questions", items: [
                    "Why can't I find a topic? Use search by condition or symptom.",
                    "Why are some links underlined? They navigate to related topics.",
                    "Can I rely on this alone for patient care? No. Use it with clinical judgment and local policy."
                ])
            ]
        ),
        InfoPage(
            id: "report-a-bug",
            title: "Report a Bug",
            subtitle: "Submit crashes, errors, or content issues",
            icon: "ladybug.fill",
            accentColor: .orange,
            sections: [
                InfoPageSection(title: "What to Send", items: [
                    "Describe what you expected and what happened instead.",
                    "Include the topic or tool involved.",
                    "If reproducible, list the steps that trigger the problem."
                ]),
                InfoPageSection(title: "Where to Report", items: [
                    "Email bug reports to: amcgowan12@rrtxapp.com"
                ])
            ]
        )
    ]

    static let allPages = howToPages + dataAndPrivacyPages + supportPages
}

struct InfoPageSection: Hashable {
    let title: String
    let items: [String]
}

struct InfoPageRow: View {
    let page: InfoPage

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(page.accentColor.opacity(0.12))
                    .frame(width: 42, height: 42)

                Image(systemName: page.icon)
                    .font(.headline)
                    .foregroundColor(page.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(page.title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(page.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
}

struct InfoPageView: View {
    let page: InfoPage

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(page.title, systemImage: page.icon)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(page.accentColor)

                    Text(page.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.rrSectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.rrEmphasisBackground, lineWidth: 1)
                )

                ForEach(page.sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        ForEach(section.items, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(page.accentColor)
                                Text(item)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rrNeutralCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.rrEmphasisBackground, lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .background(Color.rrPageBackground)
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
