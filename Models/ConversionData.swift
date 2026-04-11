import Foundation

// MARK: - Conversion Table Models

struct ConversionTable: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let columns: [String]
    let rows: [ConversionRow]
    let footnotes: [String]
    let medicationEntries: [MedicationReferenceEntry]?

    init(
        title: String,
        subtitle: String,
        icon: String,
        columns: [String],
        rows: [ConversionRow],
        footnotes: [String],
        medicationEntries: [MedicationReferenceEntry]? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.columns = columns
        self.rows = rows
        self.footnotes = footnotes
        self.medicationEntries = medicationEntries
    }
}

struct ConversionRow: Identifiable {
    let id = UUID()
    let cells: [String]
    let isHighlighted: Bool
}

enum MedicationSortMode: String, CaseIterable, Identifiable {
    case alphabetical = "A-Z"
    case medicationClass = "Class"

    var id: String { rawValue }
}

struct MedicationReferenceEntry: Identifiable {
    let id = UUID()
    let name: String
    let medicationClass: String
    let dose: String
    let form: String
    let halfLife: String
    let timeToOnset: String
    let doseAdjustment: String
    let contraindications: String
    let pearls: String

    var row: ConversionRow {
        ConversionRow(
            cells: [
                name,
                medicationClass,
                dose,
                form,
                halfLife,
                timeToOnset,
                contraindications,
                doseAdjustment,
                pearls
            ],
            isHighlighted: false
        )
    }
}

private struct MedicationClassProfile {
    let halfLife: String
    let timeToOnset: String
    let doseAdjustment: String
}

private struct MedicationReferenceOverride {
    let form: String?
    let halfLife: String?
    let timeToOnset: String?
    let doseAdjustment: String?
    let contraindications: String?
    let pearls: [String]
}

private struct MedicationGuideEntry {
    let name: String
    let dose: String
    let route: String
    let contraindications: String
    let notes: String
}

private struct MedicationGuideAggregate {
    var doses: [String] = []
    var routes: [String] = []
    var contraindications: [String] = []
    var notes: [String] = []

    mutating func append(_ entry: MedicationGuideEntry) {
        append(entry.dose, to: &doses)
        append(entry.route, to: &routes)
        append(entry.contraindications, to: &contraindications)
        append(entry.notes, to: &notes)
    }

    private func append(_ value: String, to values: inout [String]) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !values.contains(trimmed) else { return }
        values.append(trimmed)
    }
}

private enum MedicationReferenceBuilder {
    static let trackedResources = ["content", "Symptoms"]

    static let normalizedNames: [String: String] = [
        "Adenosine (diagnostic)": "Adenosine",
        "Albuterol (continuous neb)": "Albuterol",
        "Alteplase (tPA) — full dose": "Alteplase",
        "Alteplase — catheter-directed (CDL)": "Alteplase",
        "Alteplase — reduced dose": "Alteplase",
        "Aminocaproic acid (Amicar)": "Aminocaproic acid",
        "Atropine (for organophosphate)": "Atropine",
        "Bumex (Bumetanide)": "Bumetanide",
        "Dextrose (D50)": "Dextrose 50%",
        "Dextrose 50% (D50)": "Dextrose 50%",
        "Desmopressin (DDAVP)": "DDAVP",
        "Cyproheptadine (for withdrawal)": "Cyproheptadine",
        "Calcium chloride (CaCl2)": "Calcium chloride",
        "Calcium chloride 10%": "Calcium chloride",
        "Dantrolene (second-line for withdrawal)": "Dantrolene",
        "DDAVP (desmopressin)": "DDAVP",
        "Dexamethasone (high-dose)": "Dexamethasone",
        "Diazepam (for withdrawal)": "Diazepam",
        "Enoxaparin/Lovenox (LMWH)": "Enoxaparin",
        "Epinephrine (IM)": "Epinephrine",
        "Epinephrine infusion": "Epinephrine",
        "FFP (fresh frozen plasma)": "FFP",
        "Furosemide (Lasix)": "Furosemide",
        "KCl (IV)": "Potassium chloride",
        "KCl (oral)": "Potassium chloride",
        "KCl (potassium chloride)": "Potassium chloride",
        "KCl replacement": "Potassium chloride",
        "Ketamine (RSI)": "Ketamine",
        "Lidocaine 1%": "Lidocaine",
        "Lorazepam (Ativan)": "Lorazepam",
        "Lorazepam (for withdrawal)": "Lorazepam",
        "Metoprolol Tartrate": "Metoprolol tartrate",
        "Methylprednisolone (pulse)": "Methylprednisolone",
        "Midazolam (for withdrawal)": "Midazolam",
        "Midazolam gtt": "Midazolam",
        "MgSO4": "Magnesium sulfate",
        "Norepinephrine (Levophed)": "Norepinephrine",
        "Norepinephrine (if shock)": "Norepinephrine",
        "Normal saline (0.9% NaCl)": "Normal saline",
        "Normal saline (NS)": "Normal saline",
        "Normal Saline": "Normal saline",
        "Normal Saline (trach)": "Normal saline",
        "Ondansetron (Zofran)": "Ondansetron",
        "Propofol (rescue for withdrawal)": "Propofol",
        "Quetiapine (Seroquel)": "Quetiapine",
        "Regular insulin (HIE)": "Regular insulin",
        "Rocuronium (if RSI needed)": "Rocuronium",
        "Rocuronium (RSI)": "Rocuronium",
        "Sodium bicarb": "Sodium bicarbonate",
        "Sodium bicarbonate (urinary alkalinization)": "Sodium bicarbonate",
        "Valproic acid": "Valproate",
        "Tranexamic acid (TXA)": "Tranexamic acid",
        "TXA (tranexamic acid)": "Tranexamic acid",
        "(tramatic hemorrhage)Tranexamic acid (TXA)": "Tranexamic acid"
    ]

    static let excludedNames: Set<String> = [
        "Broad-spectrum antibiotics",
        "Cisatracurium or rocuronium",
        "Cold IV fluids",
        "Heliox (70:30 or 80:20)",
        "Heliox (80:20 or 70:30)",
        "Insulin + dextrose",
        "IV Crystalloid",
        "IVIG",
        "Morphine / Hydromorphone",
        "Nicardipine or Clevidipine",
        "Nitroglycerin infusion adjuncts",
        "Normal saline or LR",
        "Papaverine (via IR catheter)",
        "Platelet transfusion",
        "Plasma exchange (PLEX)",
        "Plasmapheresis (PLEX)",
        "Procedural sedation",
        "Regular insulin + Dextrose",
        "Synchronized cardioversion"
    ]

    static func makeTable() -> ConversionTable {
        var aggregates: [String: MedicationGuideAggregate] = [:]

        for entry in guideEntries() + supplementalEntries() {
            let normalizedName = normalizedNames[entry.name] ?? entry.name
            guard !excludedNames.contains(normalizedName) else { continue }
            aggregates[normalizedName, default: MedicationGuideAggregate()].append(
                MedicationGuideEntry(
                    name: normalizedName,
                    dose: entry.dose,
                    route: entry.route,
                    contraindications: entry.contraindications,
                    notes: entry.notes
                )
            )
        }

        let medicationEntries = aggregates.keys.sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }.map { name in
            buildMedicationReferenceEntry(
                name: name,
                aggregate: aggregates[name] ?? MedicationGuideAggregate()
            )
        }

        return ConversionTable(
            title: "Medication Reference",
            subtitle: "Guide-derived medication reference with sortable class groupings",
            icon: "pills.fill",
            columns: [
                "Medication",
                "Class",
                "Dose",
                "Form",
                "1/2 Life",
                "Time to Onset",
                "Contraindications",
                "Dose Modification",
                "Pearls"
            ],
            rows: medicationEntries.map(\.row),
            footnotes: [
                "Derived from medication and drug tables in `content.json`, `Symptoms.json`, and the existing tools reference data.",
                "This is an aggregation layer: individual topic pages remain the source for full condition-specific context.",
                "The sort control in the medication tool switches between alphabetical ordering and class-based ordering.",
                "Form is derived from the routes used across the topic guides. Half-life, onset, contraindications, and dose-modification fields use medication-specific data when available and otherwise fall back to class-level rapid-reference summaries.",
                "Esmolol has a medication-specific override based on FDA labeling and cardiology reference material."
            ],
            medicationEntries: medicationEntries
        )
    }

    static func buildMedicationReferenceEntry(
        name: String,
        aggregate: MedicationGuideAggregate
    ) -> MedicationReferenceEntry {
        let medicationClass = medicationClass(for: name)
        let profile = classProfile(for: medicationClass)
        let override = medicationOverride(for: name)
        let pearls = buildPearls(for: aggregate, overridePearls: override?.pearls ?? [])
        let form = override?.form ?? aggregate.routes.joined(separator: "\n")
        return MedicationReferenceEntry(
            name: name,
            medicationClass: medicationClass,
            dose: aggregate.doses.joined(separator: "\n"),
            form: form.isEmpty ? "See dose regimen" : form,
            halfLife: override?.halfLife ?? profile.halfLife,
            timeToOnset: override?.timeToOnset ?? profile.timeToOnset,
            doseAdjustment: override?.doseAdjustment ?? profile.doseAdjustment,
            contraindications: override?.contraindications ?? (
                aggregate.contraindications.isEmpty
                ? defaultContraindications(for: medicationClass)
                : aggregate.contraindications.joined(separator: "\n")
            ),
            pearls: pearls
        )
    }

    static func extractFrequency(from doses: [String]) -> String {
        let patterns = [
            #"q\d+(?:-\d+)?\s?(?:min|h|hr|hrs|day|days)"#,
            #"\b(?:daily|BID|TID|QID|PRN)\b"#,
            #"continuous(?:ly)?(?:\s(?:neb|infusion))?"#,
            #"over\s\d+(?:-\d+)?\s?(?:min|h|hr|hrs)"#,
            #"single dose"#,
            #"bolus"#,
            #"infusion"#,
            #"weekly"#,
            #"monthly"#
        ]

        let matches = doses.flatMap { dose in
            patterns.flatMap { pattern -> [String] in
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                    return []
                }
                let range = NSRange(dose.startIndex..., in: dose)
                return regex.matches(in: dose, range: range).compactMap {
                    Range($0.range, in: dose).map { String(dose[$0]) }
                }
            }
        }

        let unique = matches.reduce(into: [String]()) { partialResult, match in
            let trimmed = match.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !partialResult.contains(trimmed) else { return }
            partialResult.append(trimmed)
        }

        return unique.isEmpty ? "See dose regimen" : unique.joined(separator: "\n")
    }

    static func buildPearls(for aggregate: MedicationGuideAggregate, overridePearls: [String]) -> String {
        var pearls: [String] = []
        pearls.append(contentsOf: overridePearls)
        pearls.append(contentsOf: aggregate.notes)
        return pearls.joined(separator: "\n")
    }

    static func defaultContraindications(for medicationClass: String) -> String {
        switch medicationClass {
        case "Anticoagulant / Antiplatelet":
            return "Active bleeding or major uncontrolled hemorrhage"
        case "Thrombolytic / Hemostatic":
            return "Active bleeding, recent major intracranial event, or other therapy-specific bleeding contraindication"
        case "Vasopressor / Inotrope":
            return "No absolute contraindication in shock; use with close hemodynamic monitoring"
        case "Fluid / Electrolyte / Glucose":
            return "Use with caution in volume overload, osmotic shifts, or relevant electrolyte derangements"
        default:
            return "See topic-specific context"
        }
    }

    static func classProfile(for medicationClass: String) -> MedicationClassProfile {
        switch medicationClass {
        case "Analgesic / Antipyretic":
            return MedicationClassProfile(
                halfLife: "Usually short to intermediate; varies by agent",
                timeToOnset: "Minutes to hours depending on route",
                doseAdjustment: "Reduce in hepatic impairment; some agents also need renal adjustment",
            )
        case "Antibiotic / Antimicrobial":
            return MedicationClassProfile(
                halfLife: "Typically hours; varies by renal clearance and formulation",
                timeToOnset: "Usually within 30-60 min of IV dosing",
                doseAdjustment: "Renal adjustment is common; hepatic adjustment depends on agent",
            )
        case "Anticoagulant / Antiplatelet":
            return MedicationClassProfile(
                halfLife: "Usually hours; effect duration may exceed serum half-life",
                timeToOnset: "Minutes to hours depending on route and agent",
                doseAdjustment: "Adjust for renal function, weight, bleeding risk, and planned procedures",
            )
        case "Antiarrhythmic / Rate Control":
            return MedicationClassProfile(
                halfLife: "Agent-specific; ranges from seconds to weeks",
                timeToOnset: "Usually minutes with IV therapy",
                doseAdjustment: "Adjust for hepatic/renal function, QT, blood pressure, and structural heart disease",
            )
        case "Antidote / Reversal":
            return MedicationClassProfile(
                halfLife: "Often shorter than the toxin or target drug; monitor for recurrence",
                timeToOnset: "Often minutes",
                doseAdjustment: "Titrate to clinical response; repeated dosing may be required",
            )
        case "Antiemetic / GI":
            return MedicationClassProfile(
                halfLife: "Generally hours; formulation-specific",
                timeToOnset: "Usually 15-60 min",
                doseAdjustment: "Adjust for QT risk, hepatic dysfunction, and sedation burden",
            )
        case "Antipsychotic / Sedation Adjunct":
            return MedicationClassProfile(
                halfLife: "Usually hours to days depending on agent",
                timeToOnset: "Usually 15-60 min IV/IM; longer PO",
                doseAdjustment: "Use lower doses in elderly patients, hepatic impairment, and prolonged QT",
            )
        case "Antiseizure":
            return MedicationClassProfile(
                halfLife: "Hours to days depending on agent",
                timeToOnset: "Usually minutes with IV loading",
                doseAdjustment: "Renal or hepatic adjustment is common; titrate to response and drug level when relevant",
            )
        case "Benzodiazepine":
            return MedicationClassProfile(
                halfLife: "Short, intermediate, or long depending on agent",
                timeToOnset: "Minutes IV/IN; longer PO",
                doseAdjustment: "Use lower doses in elderly patients and hepatic dysfunction; monitor respiratory status",
            )
        case "Blood Product / Factor Replacement":
            return MedicationClassProfile(
                halfLife: "Product-specific; effect depends on factor kinetics and ongoing consumption",
                timeToOnset: "Immediate to within transfusion period",
                doseAdjustment: "Dose to clinical bleed severity and measured factor/fibrinogen targets",
            )
        case "Bronchodilator / Airway":
            return MedicationClassProfile(
                halfLife: "Usually hours; inhaled onset is rapid",
                timeToOnset: "Minutes",
                doseAdjustment: "Adjust to response, tachyarrhythmia burden, and route of delivery",
            )
        case "Corticosteroid":
            return MedicationClassProfile(
                halfLife: "Biologic effect exceeds serum half-life",
                timeToOnset: "Hours; not immediate for most indications",
                doseAdjustment: "Use lowest effective dose; account for hyperglycemia, infection risk, and taper needs",
            )
        case "Diuretic":
            return MedicationClassProfile(
                halfLife: "Usually hours; effect duration depends on renal function",
                timeToOnset: "Minutes IV; longer PO",
                doseAdjustment: "Titrate to urine output and renal function; monitor K, Mg, Na, and volume status",
            )
        case "Endocrine / Hormonal":
            return MedicationClassProfile(
                halfLife: "Agent-specific; may be prolonged in endocrine therapies",
                timeToOnset: "Minutes to hours depending on agent",
                doseAdjustment: "Adjust to severity, body weight, and lab response; monitor glycemia and sodium where relevant",
            )
        case "Fluid / Electrolyte / Glucose":
            return MedicationClassProfile(
                halfLife: "Not applicable; effect depends on distribution and ongoing losses",
                timeToOnset: "Immediate to minutes",
                doseAdjustment: "Titrate to labs, hemodynamics, renal function, and risk of overcorrection",
            )
        case "Hematology / Oncology Targeted":
            return MedicationClassProfile(
                halfLife: "Often prolonged; effect duration may outlast the serum half-life",
                timeToOnset: "Usually hours",
                doseAdjustment: "Coordinate with specialty guidance; account for cytopenias, renal function, and infection risk",
            )
        case "Neuromuscular / Cholinergic":
            return MedicationClassProfile(
                halfLife: "Typically short to intermediate",
                timeToOnset: "Minutes",
                doseAdjustment: "Titrate to airway secretions, muscle strength, or reversal effect; consider renal function",
            )
        case "Opioid":
            return MedicationClassProfile(
                halfLife: "Short to intermediate for most acute formulations; longer for transdermal products",
                timeToOnset: "Minutes IV; longer PO/transdermal",
                doseAdjustment: "Reduce in elderly patients and renal/hepatic dysfunction; account for cross-tolerance when rotating",
            )
        case "Sedative / Anesthetic":
            return MedicationClassProfile(
                halfLife: "Short to intermediate; context-sensitive half-life may lengthen with prolonged infusion",
                timeToOnset: "Seconds to minutes IV",
                doseAdjustment: "Titrate to effect; lower doses in shock, elderly patients, and organ dysfunction",
            )
        case "Thrombolytic / Hemostatic":
            return MedicationClassProfile(
                halfLife: "Usually short serum half-life with clinically significant downstream effect",
                timeToOnset: "Minutes",
                doseAdjustment: "Adjust to weight and bleeding risk; use specialty or protocol-based dosing",
            )
        case "Toxicology Support":
            return MedicationClassProfile(
                halfLife: "Varies by agent and route",
                timeToOnset: "Minutes to hours",
                doseAdjustment: "Titrate to clinical response and poison-control guidance",
            )
        case "Vasodilator / Antihypertensive":
            return MedicationClassProfile(
                halfLife: "Often short for titratable IV agents; longer for oral agents",
                timeToOnset: "Minutes IV; longer PO",
                doseAdjustment: "Titrate to blood pressure and end-organ perfusion; account for renal/hepatic function",
            )
        case "Vasopressor / Inotrope":
            return MedicationClassProfile(
                halfLife: "Usually minutes; effect depends on continuous infusion",
                timeToOnset: "Seconds to minutes",
                doseAdjustment: "Titrate continuously to MAP, cardiac output, lactate, and rhythm tolerance",
            )
        default:
            return MedicationClassProfile(
                halfLife: "Agent-specific",
                timeToOnset: "Agent-specific",
                doseAdjustment: "Adjust to indication, organ function, and bedside response",
            )
        }
    }

    static func medicationOverride(for name: String) -> MedicationReferenceOverride? {
        switch name {
        case "Esmolol":
            return MedicationReferenceOverride(
                form: "IV bolus and continuous IV infusion",
                halfLife: "~9 min",
                timeToOnset: "Within ~2 min",
                doseAdjustment: "No renal dose adjustment. Titrate to heart rate/BP; reduce or stop for bradycardia, hypotension, or heart block. Use extra caution with low EF or active bronchospasm.",
                contraindications: "Sinus bradycardia, greater-than-first-degree heart block, cardiogenic shock, overt heart failure, decompensated HF, sick sinus syndrome without a pacemaker, severe pulmonary HTN, and known hypersensitivity.",
                pearls: [
                    "Ultra-short acting beta-1 blocker useful when rapid titration or quick offset is important.",
                    "Adult IV dosing: 500 mcg/kg loading dose over 1 min, then 50 mcg/kg/min infusion; may repeat loading dose and step up infusion to 100, 150, 200 mcg/kg/min based on response."
                ]
            )
        default:
            return nil
        }
    }

    static func medicationClass(for name: String) -> String {
        switch name {
        case "Acetaminophen", "Ibuprofen", "Ketorolac":
            return "Analgesic / Antipyretic"
        case "Ampicillin", "Ampicillin-sulbactam", "Acyclovir", "Azithromycin", "Ceftriaxone",
             "Meropenem", "Micafungin", "Piperacillin-Tazobactam", "Vancomycin":
            return "Antibiotic / Antimicrobial"
        case "Apixaban", "Bivalirudin", "Clopidogrel", "Enoxaparin", "Heparin", "Ticagrelor", "Rivaroxaban", "Aspirin":
            return "Anticoagulant / Antiplatelet"
        case "Adenosine", "Amiodarone", "Atropine", "Digoxin", "Diltiazem", "Esmolol", "Labetalol",
             "Lidocaine", "Magnesium sulfate", "Metoprolol", "Metoprolol succinate", "Metoprolol tartrate",
             "Procainamide", "Propranolol", "Verapamil":
            return "Antiarrhythmic / Rate Control"
        case "Activated charcoal", "High-dose insulin (regular)", "Lipid emulsion 20%", "Mannitol":
            return "Toxicology Support"
        case "Andexanet alfa", "Digoxin immune Fab", "FFP", "Flumazenil", "Glucagon", "Idarucizumab (Praxbind)",
             "Naloxone", "Protamine sulfate", "Sugammadex", "Vitamin K (phytonadione)":
            return "Antidote / Reversal"
        case "Erythromycin", "Famotidine", "Lactulose", "Metoclopramide", "Octreotide", "Ondansetron",
             "Pantoprazole", "Prochlorperazine", "Promethazine", "Rifaximin":
            return "Antiemetic / GI"
        case "Aripiprazole", "Haloperidol", "Olanzapine", "Quetiapine", "Risperidone", "Valproic acid":
            return "Antipsychotic / Sedation Adjunct"
        case "Fosphenytoin", "Levetiracetam", "Phenobarbital", "Valproate":
            return "Antiseizure"
        case "Alprazolam", "Clonazepam", "Diazepam", "Lorazepam", "Midazolam", "Oxazepam":
            return "Benzodiazepine"
        case "4-factor PCC (Kcentra)", "Caplacizumab", "Cryoprecipitate", "FEIBA", "Recombinant factor VIII",
             "Recombinant factor IX", "rFVIIa (NovoSeven)", "vWF-containing concentrate":
            return "Blood Product / Factor Replacement"
        case "Albuterol", "Diphenhydramine", "Epinephrine", "Glycopyrrolate", "Ipratropium",
             "Racemic epinephrine (neb)", "Terbutaline":
            return "Bronchodilator / Airway"
        case "Dexamethasone", "Hydrocortisone", "Methylprednisolone", "Prednisone":
            return "Corticosteroid"
        case "Bumetanide", "Furosemide", "Metolazone", "Spironolactone", "Torsemide":
            return "Diuretic"
        case "Calcitonin (salmon)", "DDAVP", "Fludrocortisone", "Levothyroxine (T4) IV",
             "Liothyronine (T3) IV", "PTU", "SSKI (Iodine)":
            return "Endocrine / Hormonal"
        case "3% NaCl (hypertonic saline)", "Calcium chloride", "Calcium gluconate", "D5W (5% dextrose in water)",
             "Dextrose 10% (D10)", "Dextrose 50%", "Normal saline", "Oral urea",
             "Potassium chloride", "Sodium bicarbonate", "Thiamine":
            return "Fluid / Electrolyte / Glucose"
        case "Allopurinol", "Anakinra", "Ecallantide (Kalbitor)", "Eculizumab", "Hydroxyurea",
             "Icatibant (Firazyr)", "Rasburicase (Elitek)", "Rituximab", "Tocilizumab (Actemra)":
            return "Hematology / Oncology Targeted"
        case "Neostigmine", "Physostigmine", "Pralidoxime (2-PAM)", "Pyridostigmine":
            return "Neuromuscular / Cholinergic"
        case "Fentanyl", "Fentanyl patch", "Hydrocodone", "Hydromorphone", "Meperidine", "Morphine", "Oxycodone":
            return "Opioid"
        case "Dexmedetomidine (for withdrawal)", "Ketamine", "Propofol", "Rocuronium", "Succinylcholine (low-dose)":
            return "Sedative / Anesthetic"
        case "Alteplase", "Aminocaproic acid", "C1 inhibitor (Berinert/Cinryze)", "Denosumab", "Patiromer",
             "Sevelamer", "Streptokinase / Anistreplase", "Tenecteplase", "Tranexamic acid":
            return "Thrombolytic / Hemostatic"
        case "Clevidipine", "Fenoldopam", "Hydralazine", "Nicardipine", "Nitroglycerin", "Nitroprusside":
            return "Vasodilator / Antihypertensive"
        case "Dobutamine", "Dopamine", "Milrinone", "Norepinephrine", "Phenylephrine", "Vasopressin":
            return "Vasopressor / Inotrope"
        default:
            return "Other / Specialty"
        }
    }

    static func guideEntries() -> [MedicationGuideEntry] {
        trackedResources.flatMap { loadEntries(resource: $0) }
    }

    static func loadEntries(resource: String) -> [MedicationGuideEntry] {
        guard
            let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let raw = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }

        return parseDrugTables(from: raw)
    }

    static func parseDrugTables(from raw: String) -> [MedicationGuideEntry] {
        let fieldRegex = try? NSRegularExpression(
            pattern: #""(name|dose|route|contraindications|notes)"\s*:\s*"((?:\\.|[^"\\])*)""#
        )

        var entries: [MedicationGuideEntry] = []
        var currentFields: [String: String] = [:]
        var insideDrugTable = false
        var bracketDepth = 0

        for line in raw.components(separatedBy: .newlines) {
            if line.contains(#""type": "drugTable""#) {
                insideDrugTable = true
                bracketDepth = 0
            }

            guard insideDrugTable else { continue }

            bracketDepth += line.filter { $0 == "[" }.count
            bracketDepth -= line.filter { $0 == "]" }.count

            if let regex = fieldRegex,
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let keyRange = Range(match.range(at: 1), in: line),
               let valueRange = Range(match.range(at: 2), in: line) {
                let key = String(line[keyRange])
                let value = decodeJSONStringLiteral(String(line[valueRange]))
                currentFields[key] = value

                if key == "notes", let entry = buildEntry(from: currentFields) {
                    entries.append(entry)
                    currentFields.removeAll(keepingCapacity: true)
                }
            }

            if bracketDepth <= 0 && !line.contains(#""drugTable""#) && !line.contains(#""drugs""#) {
                insideDrugTable = false
                currentFields.removeAll(keepingCapacity: true)
            }
        }

        return entries
    }

    static func buildEntry(from fields: [String: String]) -> MedicationGuideEntry? {
        guard
            let name = fields["name"]?.trimmingCharacters(in: .whitespacesAndNewlines),
            let dose = fields["dose"],
            let route = fields["route"],
            let notes = fields["notes"],
            !name.isEmpty
        else {
            return nil
        }

        return MedicationGuideEntry(
            name: name,
            dose: dose,
            route: route,
            contraindications: fields["contraindications"] ?? "",
            notes: notes
        )
    }

    static func decodeJSONStringLiteral(_ value: String) -> String {
        let wrapped = "\"\(value)\""
        guard let data = wrapped.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(String.self, from: data) else {
            return value
        }
        return decoded
    }

    static func supplementalEntries() -> [MedicationGuideEntry] {
        [
            MedicationGuideEntry(
                name: "Alprazolam",
                dose: "1 mg equivalents",
                route: "PO",
                contraindications: "Taper gradually to avoid withdrawal",
                notes: "Included in the benzodiazepine conversion tool."
            ),
            MedicationGuideEntry(
                name: "Clonazepam",
                dose: "0.5-1 mg equivalents",
                route: "PO",
                contraindications: "Taper gradually to avoid withdrawal",
                notes: "Included in the benzodiazepine conversion tool."
            ),
            MedicationGuideEntry(
                name: "Fentanyl patch",
                dose: "25 mcg/hr patch example",
                route: "Transdermal",
                contraindications: "For stable chronic pain only",
                notes: "Included in the opioid conversion tool."
            ),
            MedicationGuideEntry(
                name: "Hydrocodone",
                dose: "10 mg PO q6h example",
                route: "PO",
                contraindications: "Monitor total acetaminophen exposure in combination products",
                notes: "Included in the opioid conversion tool."
            ),
            MedicationGuideEntry(
                name: "Hydromorphone",
                dose: "2 mg IV q3h or 6 mg PO q4h examples",
                route: "IV / PO",
                contraindications: "Use caution in renal or hepatic impairment",
                notes: "Alternative opioid in the conversion tool."
            ),
            MedicationGuideEntry(
                name: "Morphine",
                dose: "30 mg PO q4h or 60 mg IV/day equivalents",
                route: "PO / IV",
                contraindications: "Reduce or avoid in significant renal impairment",
                notes: "Equianalgesic reference in the opioid conversion tool."
            ),
            MedicationGuideEntry(
                name: "Oxazepam",
                dose: "Symptom-triggered AWS option",
                route: "PO",
                contraindications: "Preferred in hepatic impairment",
                notes: "Referenced in the benzodiazepine conversion tool."
            ),
            MedicationGuideEntry(
                name: "Oxycodone",
                dose: "10-20 mg PO q4h examples",
                route: "PO",
                contraindications: "Reduce for hepatic impairment",
                notes: "Equianalgesic reference in the opioid conversion tool."
            ),
            MedicationGuideEntry(
                name: "Streptokinase / Anistreplase",
                dose: "Agent-specific fibrinolytic dosing",
                route: "IV",
                contraindications: "Prior exposure or allergic reaction is a relative contraindication",
                notes: "Referenced in the fibrinolytic contraindications tool."
            )
        ]
    }
}

// MARK: - Share Text

extension ConversionTable {
    var shareText: String {
        var lines: [String] = []
        lines.append(title.uppercased())
        lines.append(subtitle)
        lines.append("")

        lines.append(columns.joined(separator: "  |  "))
        lines.append(String(repeating: "─", count: 60))

        for row in rows {
            let clean = row.cells.map {
                $0.replacingOccurrences(of: "!!", with: "")
                  .replacingOccurrences(of: "**", with: "")
            }
            lines.append(clean.joined(separator: "  |  "))
        }
        lines.append("")

        if !footnotes.isEmpty {
            lines.append("── Key Principles ──")
            for note in footnotes {
                let clean = note
                    .replacingOccurrences(of: "!!", with: "")
                    .replacingOccurrences(of: "**", with: "")
                lines.append("  • \(clean)")
            }
        }

        lines.append("")
        lines.append("— Rapid Response Clinical Reference")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Static Data

extension ConversionTable {

    static var medicationReference: ConversionTable {
        MedicationReferenceBuilder.makeTable()
    }

    static let opioidConversions = ConversionTable(
        title: "Opioid Common Dosing",
        subtitle: "Common starting doses for opioid-naïve patients",
        icon: "pill.fill",
        columns: ["Medication", "Dose", "Route / Frequency"],
        rows: [
            ConversionRow(cells: [
                "Oxycodone",
                "5 mg",
                "PO q4–6h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Oxycodone",
                "10 mg",
                "PO q4–6h PRN (moderate–severe)"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Hydromorphone (Dilaudid)",
                "0.5–1 mg",
                "IV q3–4h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Hydromorphone (Dilaudid)",
                "2 mg",
                "IV q3–4h PRN (moderate–severe)"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Hydromorphone (Dilaudid)",
                "2–4 mg",
                "PO q4–6h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Morphine",
                "2–4 mg",
                "IV q3–4h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Morphine",
                "15 mg",
                "PO q4h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Fentanyl",
                "25–50 mcg",
                "IV q1–2h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Hydrocodone / APAP",
                "5/325 mg",
                "PO q4–6h PRN"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Tramadol",
                "50 mg",
                "PO q6h PRN"
            ], isHighlighted: false)
        ],
        footnotes: [
            "Doses shown are !!common starting doses for opioid-naïve adults!! — titrate to effect",
            "!!Renal impairment!!: avoid morphine (active metabolites accumulate) — prefer hydromorphone or fentanyl",
            "!!Hepatic impairment!!: reduce doses and extend intervals for all opioids",
            "Elderly / frail: start at lower end of dose range",
            "**Breakthrough dose** = 10–20% of total daily opioid dose",
            "Always co-prescribe a bowel regimen (senna + docusate) with scheduled opioids"
        ]
    )

    static let benzodiazepineConversions = ConversionTable(
        title: "Benzodiazepine Conversions",
        subtitle: "Equivalent dosing, alcohol withdrawal, & taper guidance",
        icon: "cross.vial.fill",
        columns: ["If pt is taking…", "Equivalent dose is…", "Clinical context"],
        rows: [
            ConversionRow(cells: [
                "Diazepam 10 mg PO q6h",
                "Lorazepam 2 mg PO/IV q6h",
                "General anxiety / withdrawal"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Lorazepam 2 mg IV q4h (12 mg/day)",
                "Diazepam 50–60 mg PO daily",
                "Alcohol withdrawal"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Diazepam 20 mg PO q2h × 3 doses",
                "Lorazepam 4 mg IV q2h × 3 doses",
                "!!Front-loading for severe AWS!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Clonazepam 1 mg PO BID",
                "Lorazepam 2 mg PO BID",
                "Taper conversion"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Alprazolam 1 mg PO TID",
                "Diazepam 10 mg PO TID",
                "Taper conversion"
            ], isHighlighted: false)
        ],
        footnotes: [
            "**Key equivalency**: Diazepam 10 mg ≈ Lorazepam 2 mg ≈ Clonazepam 0.5 mg ≈ Alprazolam 1 mg",
            "Lorazepam has 1:4–5 potency ratio to diazepam",
            "Midazolam is approx half as potent as lorazepam (1:2 ratio)",
            "**Alcohol withdrawal — Mild (CIWA <10):** Diazepam 10 mg PO q6h × 4 days with taper, OR symptom-triggered dosing",
            "**Alcohol withdrawal — Moderate (CIWA 10–18):** Diazepam 10 mg PO q1h PRN for CIWA ≥10, OR lorazepam 2–4 mg IV q1h PRN",
            "**Alcohol withdrawal — Severe (CIWA ≥19):** !!Front-load!! with diazepam 10–20 mg IV/PO q2h or lorazepam 2–4 mg IV q10–15min until sedated",
            "!!Hepatic impairment!!: Prefer lorazepam or oxazepam (no active metabolites, no hepatic metabolism required)",
            "Taper benzodiazepines gradually (10–25% reduction every 1–2 weeks) to avoid withdrawal seizures",
            "!!Midazolam and high-dose IV benzodiazepines require continuous monitoring!!"
        ]
    )

    static let fibrinolyticContraindications = ConversionTable(
        title: "Fibrinolytic Contraindications",
        subtitle: "Absolute & relative contraindications to thrombolytic therapy (tPA, tenecteplase, streptokinase)",
        icon: "cross.case.fill",
        columns: ["Contraindication", "Category"],
        rows: [
            // Absolute
            ConversionRow(cells: [
                "Prior intracranial hemorrhage",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Known structural cerebral vascular lesion (AVM, aneurysm)",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Known malignant intracranial neoplasm",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Ischemic stroke within 3 months (excluding stroke within 3 hrs*)",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Suspected aortic dissection",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Active bleeding or bleeding diathesis (excluding menses)",
                "!!Absolute!!"
            ], isHighlighted: true),
            ConversionRow(cells: [
                "Significant closed-head trauma or facial trauma within 3 months",
                "!!Absolute!!"
            ], isHighlighted: true),
            // Relative
            ConversionRow(cells: [
                "History of chronic, severe, poorly controlled hypertension",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Severe uncontrolled HTN on presentation (SBP >180 or DBP >110)",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "History of ischemic stroke >3 months prior",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Traumatic or prolonged (>10 min) CPR or major surgery <3 weeks",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Recent (within 2–4 weeks) internal bleeding",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Noncompressible vascular punctures",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Recent invasive procedure",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Streptokinase/anistreplase: prior exposure (>5 days ago) or prior allergic reaction",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Pregnancy",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Active peptic ulcer",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Pericarditis or pericardial fluid",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Current anticoagulant use w/ INR >1.7 or PT >15 sec",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Age >75 years",
                "Relative"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Diabetic retinopathy",
                "Relative"
            ], isHighlighted: false)
        ],
        footnotes: [
            "!!Absolute contraindications = do NOT give fibrinolytics!! — risk of life-threatening hemorrhage outweighs benefit",
            "**Relative contraindications** = weigh risk vs benefit on a case-by-case basis; may still give if benefit clearly outweighs risk (e.g., massive STEMI, massive PE w/ shock)",
            "*Ischemic stroke within 3 hrs is an !!indication!! for tPA, not a contraindication (IV alteplase 0.9 mg/kg, max 90 mg)",
            "!!Always obtain a non-contrast CT head before giving tPA for stroke!! — must r/o hemorrhage",
            "For !!STEMI!!: primary PCI is preferred over fibrinolytics if door-to-balloon time <120 min; fibrinolytics if PCI not available within 120 min",
            "For !!massive PE!!: alteplase 100 mg IV over 2 hrs or tenecteplase weight-based bolus; consider half-dose (50 mg) in pts w/ relative contraindications",
            "!!Check coags (PT/INR, aPTT), CBC w/ platelets, and type & screen before administration!!"
        ]
    )

    static let cognitiveBiases = ConversionTable(
        title: "Cognitive Biases",
        subtitle: "Common diagnostic traps and bedside debiasing prompts",
        icon: "brain.head.profile",
        columns: ["Bias", "What It Looks Like", "Clinical Risk", "Debiasing Pearl"],
        rows: [
            ConversionRow(cells: [
                "Anchoring",
                "Locking onto the first diagnosis or the sign-out diagnosis and underweighting new data.",
                "Misses evolving shock, new hypoxemia, or a second process that no longer fits the original story.",
                "Ask: what new finding does not fit, and what diagnosis would I consider if I saw the patient fresh?"
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Premature Closure",
                "Stopping the diagnostic search once one plausible answer is found.",
                "Can miss concurrent conditions such as sepsis plus hemorrhage, PE plus pneumonia, or ACS plus arrhythmia.",
                "Force yourself to name at least one dangerous alternative before ending the workup."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Confirmation Bias",
                "Seeking data that supports your leading diagnosis while discounting conflicting evidence.",
                "Leads to selective interpretation of labs, imaging, telemetry, and consultant input.",
                "Actively look for one piece of evidence that should be present if you are right and one that argues you are wrong."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Availability Bias",
                "Recent memorable cases make a diagnosis feel more likely than it really is.",
                "Overcalls familiar diagnoses and under-recognizes uncommon but high-risk conditions.",
                "Re-center on base rates, vital-sign abnormalities, and objective findings rather than memory of the last shift."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Search Satisfaction",
                "Finding one abnormality and stopping before looking for additional pathology.",
                "Important in rapid response when one derangement does not explain the full clinical picture.",
                "After identifying one problem, ask what else could still kill this patient today."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Diagnostic Momentum",
                "A prior label gains authority as it passes from note to note or team to team.",
                "Incorrect framing persists and delays recognition of deterioration or the true cause.",
                "Review the raw data yourself: vitals, ECG, exam, meds, timeline, and recent labs."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Framing Effect",
                "The way the case is presented shapes the differential more than the patient’s actual findings.",
                "A 'stable floor patient' frame can downplay early shock or respiratory failure.",
                "Restate the case in neutral terms using only time course, vitals, exam, and objective data."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Overconfidence",
                "Too much certainty despite limited data, especially early in deterioration.",
                "Can delay escalation, consultation, repeat reassessment, or ICU transfer.",
                "Match confidence to data quality; if unstable and uncertain, escalate while you clarify."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Base Rate Neglect",
                "Ignoring how common or uncommon a diagnosis is in this setting and population.",
                "Can produce low-value testing or distract from more probable, time-sensitive diagnoses.",
                "Use prevalence plus red flags: common things are common, but instability still mandates ruling out killers first."
            ], isHighlighted: false),
            ConversionRow(cells: [
                "Triage Cueing",
                "Letting the initial bedside impression or triage label determine the whole workup.",
                "Subtle deterioration may be missed if the patient was first described as anxiety, pain, or 'just tachycardic.'",
                "Reassess from zero whenever vitals worsen, oxygen need increases, or the nurse says the patient looks different."
            ], isHighlighted: false)
        ],
        footnotes: [
            "Bias mitigation matters most when the patient is unstable, the story is incomplete, or the diagnosis seems obvious too early.",
            "A useful rapid-response habit is to ask: what is the worst plausible diagnosis, what data does not fit, and what would change management in the next 10 minutes?",
            "Shared situational awareness helps reduce bias: involve the bedside nurse, review the trend, and state your differential out loud."
        ]
    )

    static let abbreviationsReference = ConversionTable(
        title: "Abbreviations",
        subtitle: "Common abbreviations used throughout the guide",
        icon: "textformat.abc",
        columns: ["Abbreviation", "Meaning", "Notes"],
        rows: [
            ConversionRow(cells: ["ABG", "Arterial blood gas", "Used for oxygenation, ventilation, and acid-base assessment"], isHighlighted: false),
            ConversionRow(cells: ["ACE-I", "Angiotensin-converting enzyme inhibitor", "Common trigger for bradykinin-mediated angioedema"], isHighlighted: false),
            ConversionRow(cells: ["ACS", "Acute coronary syndrome", "Includes STEMI, NSTEMI, and unstable angina"], isHighlighted: false),
            ConversionRow(cells: ["ADHF", "Acute decompensated heart failure", ""], isHighlighted: false),
            ConversionRow(cells: ["AFib", "Atrial fibrillation", ""], isHighlighted: false),
            ConversionRow(cells: ["AFL", "Atrial flutter", ""], isHighlighted: false),
            ConversionRow(cells: ["AI", "Adrenal insufficiency", "Often appears in adrenal crisis and shock discussions"], isHighlighted: false),
            ConversionRow(cells: ["AKI", "Acute kidney injury", ""], isHighlighted: false),
            ConversionRow(cells: ["AMS", "Altered mental status", ""], isHighlighted: false),
            ConversionRow(cells: ["ARDS", "Acute respiratory distress syndrome", ""], isHighlighted: false),
            ConversionRow(cells: ["ASA", "Aspirin", ""], isHighlighted: false),
            ConversionRow(cells: ["AVB", "Atrioventricular block", "Heart block"], isHighlighted: false),
            ConversionRow(cells: ["AVNRT", "Atrioventricular nodal reentrant tachycardia", "Common SVT subtype"], isHighlighted: false),
            ConversionRow(cells: ["AVRT", "Atrioventricular reentrant tachycardia", "Accessory-pathway mediated SVT"], isHighlighted: false),
            ConversionRow(cells: ["BBB", "Bundle branch block", ""], isHighlighted: false),
            ConversionRow(cells: ["BiPAP", "Bilevel positive airway pressure", "Noninvasive ventilation"], isHighlighted: false),
            ConversionRow(cells: ["BP", "Blood pressure", ""], isHighlighted: false),
            ConversionRow(cells: ["BRASH", "Bradycardia, renal failure, AV nodal blocker, shock, hyperkalemia", "Syndrome causing profound bradycardia and hypotension"], isHighlighted: false),
            ConversionRow(cells: ["CABG", "Coronary artery bypass grafting", ""], isHighlighted: false),
            ConversionRow(cells: ["CAUTI", "Catheter-associated urinary tract infection", ""], isHighlighted: false),
            ConversionRow(cells: ["CBC", "Complete blood count", ""], isHighlighted: false),
            ConversionRow(cells: ["CCB", "Calcium channel blocker", ""], isHighlighted: false),
            ConversionRow(cells: ["CHF", "Congestive heart failure", ""], isHighlighted: false),
            ConversionRow(cells: ["CK", "Creatine kinase", ""], isHighlighted: false),
            ConversionRow(cells: ["CKD", "Chronic kidney disease", ""], isHighlighted: false),
            ConversionRow(cells: ["CLABSI", "Central line-associated bloodstream infection", ""], isHighlighted: false),
            ConversionRow(cells: ["CMP", "Comprehensive metabolic panel", ""], isHighlighted: false),
            ConversionRow(cells: ["COPD", "Chronic obstructive pulmonary disease", ""], isHighlighted: false),
            ConversionRow(cells: ["CPAP", "Continuous positive airway pressure", ""], isHighlighted: false),
            ConversionRow(cells: ["CPR", "Cardiopulmonary resuscitation", ""], isHighlighted: false),
            ConversionRow(cells: ["CTA", "Computed tomography angiography", ""], isHighlighted: false),
            ConversionRow(cells: ["CTPA", "CT pulmonary angiography", "CTA chest for pulmonary embolism"], isHighlighted: false),
            ConversionRow(cells: ["CVA", "Cerebrovascular accident", "Stroke"], isHighlighted: false),
            ConversionRow(cells: ["CXR", "Chest radiograph", "Chest X-ray"], isHighlighted: false),
            ConversionRow(cells: ["DBP", "Diastolic blood pressure", ""], isHighlighted: false),
            ConversionRow(cells: ["DDx", "Differential diagnosis", ""], isHighlighted: false),
            ConversionRow(cells: ["DKA", "Diabetic ketoacidosis", ""], isHighlighted: false),
            ConversionRow(cells: ["DOAC", "Direct oral anticoagulant", ""], isHighlighted: false),
            ConversionRow(cells: ["DVT", "Deep vein thrombosis", ""], isHighlighted: false),
            ConversionRow(cells: ["ECG / EKG", "Electrocardiogram", ""], isHighlighted: false),
            ConversionRow(cells: ["ECMO", "Extracorporeal membrane oxygenation", ""], isHighlighted: false),
            ConversionRow(cells: ["ED", "Emergency department", ""], isHighlighted: false),
            ConversionRow(cells: ["EF", "Ejection fraction", ""], isHighlighted: false),
            ConversionRow(cells: ["ENT", "Ear, nose, and throat", "Otolaryngology"], isHighlighted: false),
            ConversionRow(cells: ["ETCO2", "End-tidal carbon dioxide", ""], isHighlighted: false),
            ConversionRow(cells: ["ETT", "Endotracheal tube", ""], isHighlighted: false),
            ConversionRow(cells: ["FFP", "Fresh frozen plasma", ""], isHighlighted: false),
            ConversionRow(cells: ["FiO2", "Fraction of inspired oxygen", ""], isHighlighted: false),
            ConversionRow(cells: ["FVC", "Forced vital capacity", "Used in neuromuscular respiratory monitoring"], isHighlighted: false),
            ConversionRow(cells: ["GBS", "Guillain-Barre syndrome", ""], isHighlighted: false),
            ConversionRow(cells: ["GI", "Gastrointestinal", ""], isHighlighted: false),
            ConversionRow(cells: ["GOC", "Goals of care", ""], isHighlighted: false),
            ConversionRow(cells: ["HAE", "Hereditary angioedema", ""], isHighlighted: false),
            ConversionRow(cells: ["HAP", "Hospital-acquired pneumonia", ""], isHighlighted: false),
            ConversionRow(cells: ["HFrEF", "Heart failure with reduced ejection fraction", ""], isHighlighted: false),
            ConversionRow(cells: ["HFNC", "High-flow nasal cannula", ""], isHighlighted: false),
            ConversionRow(cells: ["HFpEF", "Heart failure with preserved ejection fraction", ""], isHighlighted: false),
            ConversionRow(cells: ["HIT", "Heparin-induced thrombocytopenia", ""], isHighlighted: false),
            ConversionRow(cells: ["HR", "Heart rate", ""], isHighlighted: false),
            ConversionRow(cells: ["HTN", "Hypertension", ""], isHighlighted: false),
            ConversionRow(cells: ["ICU", "Intensive care unit", ""], isHighlighted: false),
            ConversionRow(cells: ["ICS", "Intercostal space", ""], isHighlighted: false),
            ConversionRow(cells: ["IJ", "Internal jugular", ""], isHighlighted: false),
            ConversionRow(cells: ["ILD", "Interstitial lung disease", ""], isHighlighted: false),
            ConversionRow(cells: ["IM", "Intramuscular", ""], isHighlighted: false),
            ConversionRow(cells: ["IMC", "Intermediate care", "Step-down level of care"], isHighlighted: false),
            ConversionRow(cells: ["INR", "International normalized ratio", ""], isHighlighted: false),
            ConversionRow(cells: ["IO", "Intraosseous", ""], isHighlighted: false),
            ConversionRow(cells: ["IV", "Intravenous", ""], isHighlighted: false),
            ConversionRow(cells: ["IVC", "Inferior vena cava", "Often referenced on POCUS volume assessment"], isHighlighted: false),
            ConversionRow(cells: ["IVIG", "Intravenous immunoglobulin", ""], isHighlighted: false),
            ConversionRow(cells: ["JVD", "Jugular venous distension", ""], isHighlighted: false),
            ConversionRow(cells: ["LA", "Left atrium / atrial", "Interpret from context"], isHighlighted: false),
            ConversionRow(cells: ["LE", "Lower extremity", ""], isHighlighted: false),
            ConversionRow(cells: ["LMWH", "Low-molecular-weight heparin", ""], isHighlighted: false),
            ConversionRow(cells: ["LP", "Lumbar puncture", ""], isHighlighted: false),
            ConversionRow(cells: ["LR", "Lactated Ringer's", ""], isHighlighted: false),
            ConversionRow(cells: ["LV", "Left ventricle / ventricular", "Interpret from context"], isHighlighted: false),
            ConversionRow(cells: ["LVO", "Large-vessel occlusion", "Stroke thrombectomy target"], isHighlighted: false),
            ConversionRow(cells: ["MAP", "Mean arterial pressure", ""], isHighlighted: false),
            ConversionRow(cells: ["MAR", "Medication administration record", ""], isHighlighted: false),
            ConversionRow(cells: ["MAT", "Multifocal atrial tachycardia", ""], isHighlighted: false),
            ConversionRow(cells: ["MG", "Myasthenia gravis", ""], isHighlighted: false),
            ConversionRow(cells: ["MTP", "Massive transfusion protocol", ""], isHighlighted: false),
            ConversionRow(cells: ["NIF", "Negative inspiratory force", "Respiratory muscle strength"], isHighlighted: false),
            ConversionRow(cells: ["NIPPV", "Noninvasive positive-pressure ventilation", ""], isHighlighted: false),
            ConversionRow(cells: ["NMS", "Neuroleptic malignant syndrome", ""], isHighlighted: false),
            ConversionRow(cells: ["NRB", "Non-rebreather mask", ""], isHighlighted: false),
            ConversionRow(cells: ["NSTEMI", "Non-ST-elevation myocardial infarction", ""], isHighlighted: false),
            ConversionRow(cells: ["O2", "Oxygen", ""], isHighlighted: false),
            ConversionRow(cells: ["OCP", "Oral contraceptive pill", "Risk factor in venous thromboembolism topics"], isHighlighted: false),
            ConversionRow(cells: ["OD", "Overdose", ""], isHighlighted: false),
            ConversionRow(cells: ["OSA", "Obstructive sleep apnea", ""], isHighlighted: false),
            ConversionRow(cells: ["PAC", "Premature atrial contraction", ""], isHighlighted: false),
            ConversionRow(cells: ["PE", "Pulmonary embolism", ""], isHighlighted: false),
            ConversionRow(cells: ["PEA", "Pulseless electrical activity", ""], isHighlighted: false),
            ConversionRow(cells: ["PERT", "Pulmonary embolism response team", ""], isHighlighted: false),
            ConversionRow(cells: ["PLEX", "Plasma exchange", "Plasmapheresis"], isHighlighted: false),
            ConversionRow(cells: ["PMH", "Past medical history", ""], isHighlighted: false),
            ConversionRow(cells: ["PNA", "Pneumonia", ""], isHighlighted: false),
            ConversionRow(cells: ["PO", "By mouth", "Oral route"], isHighlighted: false),
            ConversionRow(cells: ["POCUS", "Point-of-care ultrasound", ""], isHighlighted: false),
            ConversionRow(cells: ["PRES", "Posterior reversible encephalopathy syndrome", ""], isHighlighted: false),
            ConversionRow(cells: ["PRN", "As needed", ""], isHighlighted: false),
            ConversionRow(cells: ["PTX", "Pneumothorax", ""], isHighlighted: false),
            ConversionRow(cells: ["PVC", "Premature ventricular contraction", ""], isHighlighted: false),
            ConversionRow(cells: ["q", "Every", "Example: q6h = every 6 hours"], isHighlighted: false),
            ConversionRow(cells: ["RA", "Room air", ""], isHighlighted: false),
            ConversionRow(cells: ["RASS", "Richmond Agitation-Sedation Scale", ""], isHighlighted: false),
            ConversionRow(cells: ["RF", "Risk factor", ""], isHighlighted: false),
            ConversionRow(cells: ["ROSC", "Return of spontaneous circulation", ""], isHighlighted: false),
            ConversionRow(cells: ["RR", "Respiratory rate", ""], isHighlighted: false),
            ConversionRow(cells: ["RSI", "Rapid sequence intubation", ""], isHighlighted: false),
            ConversionRow(cells: ["RV", "Right ventricle / ventricular", "Interpret from context"], isHighlighted: false),
            ConversionRow(cells: ["SBP", "Systolic blood pressure", ""], isHighlighted: false),
            ConversionRow(cells: ["SC", "Subcutaneous", ""], isHighlighted: false),
            ConversionRow(cells: ["SCD", "Sequential compression device", ""], isHighlighted: false),
            ConversionRow(cells: ["SOB", "Shortness of breath", ""], isHighlighted: false),
            ConversionRow(cells: ["SpO2", "Peripheral oxygen saturation", ""], isHighlighted: false),
            ConversionRow(cells: ["SSI", "Surgical site infection", ""], isHighlighted: false),
            ConversionRow(cells: ["STEMI", "ST-elevation myocardial infarction", ""], isHighlighted: false),
            ConversionRow(cells: ["SVT", "Supraventricular tachycardia", ""], isHighlighted: false),
            ConversionRow(cells: ["TCA", "Tricyclic antidepressant", ""], isHighlighted: false),
            ConversionRow(cells: ["TEE", "Transesophageal echocardiogram", ""], isHighlighted: false),
            ConversionRow(cells: ["TIA", "Transient ischemic attack", ""], isHighlighted: false),
            ConversionRow(cells: ["tPA", "Tissue plasminogen activator", "Alteplase"], isHighlighted: false),
            ConversionRow(cells: ["TTE", "Transthoracic echocardiogram", ""], isHighlighted: false),
            ConversionRow(cells: ["Tx", "Treatment", ""], isHighlighted: false),
            ConversionRow(cells: ["UA", "Urinalysis / unstable angina", "Interpret from context"], isHighlighted: false),
            ConversionRow(cells: ["UFH", "Unfractionated heparin", ""], isHighlighted: false),
            ConversionRow(cells: ["UMN", "Upper motor neuron", ""], isHighlighted: false),
            ConversionRow(cells: ["UOP", "Urine output", ""], isHighlighted: false),
            ConversionRow(cells: ["URI", "Upper respiratory infection", ""], isHighlighted: false),
            ConversionRow(cells: ["UTI", "Urinary tract infection", ""], isHighlighted: false),
            ConversionRow(cells: ["VAP", "Ventilator-associated pneumonia", ""], isHighlighted: false),
            ConversionRow(cells: ["VBG", "Venous blood gas", ""], isHighlighted: false),
            ConversionRow(cells: ["VF", "Ventricular fibrillation", ""], isHighlighted: false),
            ConversionRow(cells: ["VT", "Ventricular tachycardia", ""], isHighlighted: false),
            ConversionRow(cells: ["VTE", "Venous thromboembolism", ""], isHighlighted: false),
            ConversionRow(cells: ["WBC", "White blood cell count", ""], isHighlighted: false),
            ConversionRow(cells: ["WMA", "Wall motion abnormality", "Usually on echocardiography"], isHighlighted: false),
            ConversionRow(cells: ["WOB", "Work of breathing", ""], isHighlighted: false),
            ConversionRow(cells: ["WPW", "Wolff-Parkinson-White", "Accessory-pathway syndrome"], isHighlighted: false)
        ],
        footnotes: [
            "Abbreviations can be context-dependent; when a term could mean more than one thing, use the surrounding topic to interpret it.",
            "This page is intended as a quick-reference glossary for terms repeatedly used across the guide."
        ]
    )

    static var allTools: [ConversionTable] {
        [
            medicationReference,
            opioidConversions,
            benzodiazepineConversions,
            fibrinolyticContraindications,
            cognitiveBiases,
            abbreviationsReference
        ]
    }
}
