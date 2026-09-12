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
            ForEach(InfoPage.zollPages) { page in
                NavigationLink(destination: InfoPageView(page: page)) {
                    InfoPageRow(page: page)
                }
            }
        } header: {
            ToolSectionHeader(
                title: "ZOLL R Series",
                subtitle: "Step-by-step device operation guides",
                systemImage: "bolt.heart.fill",
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
        )
    ]

    static let zollPages: [InfoPage] = [
        InfoPage(
            id: "zoll-aed-operation",
            title: "AED Operation",
            subtitle: "Automated defibrillation step-by-step",
            icon: "bolt.heart.fill",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Power On & Attach Pads", items: [
                    "Turn Mode Selector to ON — unit beeps 4 times and green AED label lights up.",
                    "Remove all clothing from chest. Dry chest; clip excessive hair if needed.",
                    "Attach hands-free therapy electrodes per packaging instructions. Connect to OneStep cable.",
                    "If pads are not connected, ATTACH PADS message and voice prompt will sound.",
                    "Default adult energy: Shock 1 = 120 J, Shock 2 = 150 J, Shock 3 = 200 J.",
                    "Default pediatric energy (OneStep Pediatric pads): 50 J / 70 J / 85 J. Use only OneStep Pediatric pads for patients under 8 years."
                ]),
                InfoPageSection(title: "Analyze", items: [
                    "Unit automatically begins ECG analysis and displays ANALYZING ECG for 5 seconds, then STAND CLEAR.",
                    "Do not touch the patient during analysis. Ensure patient is motionless.",
                    "Analysis = three consecutive 3-second segments. Shockable if ≥2/3 segments detect shockable rhythm.",
                    "If nonshockable: NO SHOCK ADVISED displays — begin compressions per protocol.",
                    "If shockable: SHOCK ADVISED displays, unit charges automatically."
                ]),
                InfoPageSection(title: "Deliver Shock", items: [
                    "When fully charged, SHOCK button illuminates and PRESS SHOCK is announced.",
                    "A continuous tone sounds for 20 seconds, then intermittent for 10 seconds (30-second window total).",
                    "Warn everyone to STAND CLEAR. Press and hold SHOCK button until energy is delivered.",
                    "Display returns to XXX J SEL. SHOCKS:1 after delivery.",
                    "Begin CPR immediately after shock. Unit will restart analysis after the configured CPR interval."
                ]),
                InfoPageSection(title: "Key Display Messages", items: [
                    "ATTACH PADS — pads not connected to patient.",
                    "ANALYZING ECG / STAND CLEAR — analysis in progress.",
                    "SHOCK ADVISED / XXXJ READY — shockable rhythm detected, charged and ready.",
                    "NO SHOCK ADVISED — nonshockable rhythm; continue CPR.",
                    "CHECK PADS — pads disconnected or poor contact.",
                    "PUSH HARDER / GOOD COMPRESSIONS — CPR quality feedback (if OneStep CPR pads connected).",
                    "Switching to Manual: press Manual Mode softkey → press Confirm within 10 seconds."
                ])
            ]
        ),
        InfoPage(
            id: "zoll-manual-defib-pads",
            title: "Manual Defibrillation (Pads)",
            subtitle: "Hands-free therapy electrodes in Manual mode",
            icon: "bolt.fill",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Setup", items: [
                    "Turn Mode Selector to ON (4 beeps). Press Manual Mode softkey → press Confirm.",
                    "PADS selected as ECG source automatically when paddles are not connected.",
                    "Attach hands-free therapy electrodes per packaging instructions. Connect to OneStep cable.",
                    "Default adult energy: Shock 1 = 120 J, Shock 2 = 150 J, Shock 3 = 200 J.",
                    "OneStep Pediatric pads default: 50 J / 70 J / 85 J.",
                    "If escalating energy is configured, R Series auto-sets energy after each of the first two shocks."
                ]),
                InfoPageSection(title: "Select Energy & Charge", items: [
                    "Verify selected energy on display (DEFIB XXXJ SEL.). Adjust with ENERGY SELECT buttons if needed.",
                    "Press CHARGE button on front panel.",
                    "Changing energy while charging or charged disarms the unit — press CHARGE again to recharge.",
                    "When ready: SHOCK button illuminates, charge ready tone sounds, DEFIB XXXJ READY displayed."
                ]),
                InfoPageSection(title: "Deliver Shock", items: [
                    "Announce STAND CLEAR. Ensure no one is touching patient, bed rails, or connected equipment.",
                    "Press and hold SHOCK button until energy is delivered.",
                    "If not discharged within 60–120 seconds (configurable), unit auto-disarms — recharge to shock again.",
                    "Display shows XXXJ DELIVERED then returns to DEFIB XXXJ SEL."
                ]),
                InfoPageSection(title: "Troubleshooting", items: [
                    "CHECK PADS / POOR PAD CONTACT — pads not making good skin contact; check placement and connections.",
                    "DEFIB PAD SHORT — short circuit between electrodes.",
                    "Energy not delivered when SHOCK pressed — ensure DEFIB XXXJ READY is displayed before pressing."
                ])
            ]
        ),
        InfoPage(
            id: "zoll-synchronized-cardioversion",
            title: "Synchronized Cardioversion",
            subtitle: "Sync cardioversion procedure — Manual mode only",
            icon: "waveform.path.ecg",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Preparation", items: [
                    "Manual mode only. Only skilled personnel trained in ACLS should perform cardioversion.",
                    "Attach ECG electrodes (standard lead cable recommended). Attach hands-free therapy electrodes.",
                    "If using paddles as ECG source: artifact from moving paddles can mimic R-wave and trigger early discharge — avoid if possible.",
                    "Turn Mode Selector to ON → press Manual Mode → press Confirm."
                ]),
                InfoPageSection(title: "Enable Sync Mode", items: [
                    "Press Sync On/Off softkey. Display shows SYNC XXXJ SEL. and two quick beeps sound.",
                    "Sync markers (▲) appear above each detected R-wave on the ECG trace.",
                    "Verify markers are clearly visible and consistent beat to beat. Adjust LEAD or SIZE if needed.",
                    "Unit exits Sync mode automatically after each shock — press Sync On/Off again to reactivate if more shocks needed.",
                    "If DEFIB XXXJ SEL. appears instead of SYNC XXXJ SEL., press Sync On/Off again."
                ]),
                InfoPageSection(title: "Charge & Deliver Shock", items: [
                    "Select energy with ENERGY SELECT buttons. Press CHARGE (front panel or apex paddle).",
                    "Changing energy after charging disarms the unit — press CHARGE again.",
                    "When charged: SHOCK button or apex charge indicator illuminates. SYNC XXXJ READY displayed.",
                    "Announce STAND CLEAR. Verify no one is touching patient, bed, or leads. Confirm Sync markers on each R-wave.",
                    "Press and hold SHOCK button until energy is delivered with the next R-wave detection.",
                    "If not discharged within 60–120 seconds, unit auto-disarms. Unit remains in Sync mode."
                ]),
                InfoPageSection(title: "Key Warnings", items: [
                    "If ANALYZE is pressed while in Sync mode, REMOVE SYNC message appears and analysis is blocked.",
                    "For repeated shocks: reselect energy as needed, press Sync On/Off again (must show SYNC XXXJ SEL. before charging).",
                    "ECG LEAD OFF prevents synchronized discharge — check lead connections.",
                    "To return to AED mode: power off for >10 seconds then power back on."
                ])
            ]
        ),
        InfoPage(
            id: "zoll-pacing",
            title: "Transcutaneous Pacing",
            subtitle: "Noninvasive temporary pacing — Manual mode only",
            icon: "waveform.badge.plus",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Setup", items: [
                    "Manual mode only. Requires hands-free therapy electrodes (OneStep Pacing, CPR, or Complete) or separate ECG leads + pacing pads.",
                    "Turn Mode Selector to ON → Manual Mode → Confirm. Then turn Mode Selector to PACER — pacer door opens.",
                    "OneStep Pacing cable must be connected to both MFC and ECG connectors when using OneStep Pacing or Complete electrodes.",
                    "If using separate ECG electrodes + pads: connect ECG cable to rear ECG input and pacing pads to OneStep cable.",
                    "Select ECG lead P1, P2, or P3 (OneStep pads) or Lead II (separate leads). Verify R-wave detection — heart symbol flashes with each R-wave."
                ]),
                InfoPageSection(title: "Set Rate & Output", items: [
                    "Set PACER OUTPUT to 0 mA on startup.",
                    "Set PACER RATE 10–20 ppm above patient's intrinsic rate. Use 100 ppm if no intrinsic rate.",
                    "Verify pacing stimulus marker is well-positioned in diastole on the ECG trace.",
                    "Increase PACER OUTPUT until capture is achieved. Typical threshold: 40–80 mA. Ideal output = ~10% above threshold.",
                    "Rate increments in 2 ppm steps; output increments in 2 mA steps."
                ]),
                InfoPageSection(title: "Confirm Capture", items: [
                    "Electrical capture: widened QRS, loss of intrinsic rhythm, enlarged T-wave after each pacer marker.",
                    "Mechanical capture: palpate peripheral pulse — use femoral or right brachial/radial artery only (avoid mistaking muscle twitch for pulse).",
                    "Provide analgesia/sedation if patient is conscious and condition allows.",
                    "4:1 Mode: press and hold 4:1 button to withhold most pacing stimuli and observe underlying rhythm."
                ]),
                InfoPageSection(title: "Standby & Asynchronous Pacing", items: [
                    "Standby pacing: set mA 10% above capture threshold, set rate below patient's intrinsic rate — unit paces automatically if rate drops.",
                    "Asynchronous pacing: press Async Pacing On/Off softkey when ECG leads are unavailable. Display shows ASYNC PACE.",
                    "CHECK PADS / POOR PAD CONTACT alarm: cable disconnected, pads off skin, or defective cable — reconnect and press Clear Pace Alarm.",
                    "Pediatric pacing: identical procedure. Use OneStep Pediatric electrodes for patients <33 lbs (15 kg). Check skin every 30 minutes for burns."
                ])
            ]
        ),
        InfoPage(
            id: "zoll-real-cpr-help",
            title: "Real CPR Help",
            subtitle: "CPR feedback features with OneStep CPR pads",
            icon: "hand.raised.fill",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Overview", items: [
                    "Available when OneStep CPR or OneStep Complete electrodes are connected.",
                    "CPR sensor between rescuer's hands and lower sternum monitors rate and depth.",
                    "Not intended for patients under 8 years of age."
                ]),
                InfoPageSection(title: "CPR Index (R Series Plus Only)", items: [
                    "Hexagon display fills from center out as compressions approach AHA/ERC targets.",
                    "Fully filled = depth >1.75 inches and rate >90 cpm simultaneously.",
                    "RATE and/or DEPTH indicators appear when below recommended levels (80 cpm / 1.5 inches)."
                ]),
                InfoPageSection(title: "CPR Metronome", items: [
                    "Beeps at 100 cpm to guide compression rate.",
                    "Silent during AED analysis and when compressions are detected at ≥80 cpm.",
                    "In AED mode: always active during CPR intervals. In Manual/Advisory mode: active only when rate falls below threshold."
                ]),
                InfoPageSection(title: "See-Thru CPR Filter (R Series Plus Only)", items: [
                    "Filters CPR artifact from ECG to show underlying rhythm during compressions.",
                    "Activates automatically after 3–6 compressions. Filtered ECG labeled FIL displayed in Trace 2 or 3.",
                    "Always stop CPR to verify rhythm before making treatment decisions — filter does not remove all artifact.",
                    "To display: Options → Traces → Trace 2 or 3 → Filt ECG.",
                    "Filter stops if unit enters Pace mode or OneStep CPR pads are removed."
                ])
            ]
        ),
        InfoPage(
            id: "zoll-battery-maintenance",
            title: "Battery & Daily Checks",
            subtitle: "Readiness testing, battery replacement, and routine maintenance",
            icon: "battery.100.bolt",
            accentColor: .red,
            sections: [
                InfoPageSection(title: "Daily Visual Inspection", items: [
                    "Check unit is clean, no fluid spills, no visible damage.",
                    "Inspect all cables, cords, and connectors for cuts, fraying, or bent pins.",
                    "Verify paddle surfaces are clean and free of gel.",
                    "Confirm two sets of ZOLL therapy pads are available in sealed packages. Check expiration dates.",
                    "Confirm fully charged battery is installed and a spare is present."
                ]),
                InfoPageSection(title: "Battery Replacement", items: [
                    "To remove: press tab on end of battery pack inward and lift out.",
                    "To install: place the end opposite the tab into the compartment first, lower tabbed end in, press until it locks.",
                    "LOW BATTERY message during testing = replace or recharge before use.",
                    "Selecting high display brightness depletes battery faster than low brightness."
                ]),
                InfoPageSection(title: "Code Readiness Test (Automatic)", items: [
                    "Performed automatically once per day when connected to AC power.",
                    "Green checkmark = unit ready. Red X = unit not ready for therapeutic use.",
                    "If red X: connect to AC power, enter Manual mode, press Report Data → Test Log to identify the failure.",
                    "Verified components: battery, OneStep electrodes (expiry and gel condition), ECG circuitry, defibrillator charge/discharge, microprocessor, CPR circuitry."
                ]),
                InfoPageSection(title: "Manual Defibrillator Test", items: [
                    "Connect to AC power. Connect OneStep cable to test port, sealed OneStep electrodes, or paddles seated in wells.",
                    "Turn ON → Manual Mode → Confirm. Set energy to 30 J. Press CHARGE.",
                    "When charged, press SHOCK (paddles into wells with both SHOCK buttons, or SHOCK button for pads).",
                    "30J TEST OK confirms successful test. 30J TEST FAILED = contact technical service.",
                    "Changing energy away from 30 J during test disarms unit — reset to 30 J and recharge."
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

    static let allPages = howToPages + zollPages + dataAndPrivacyPages + supportPages
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
