import Foundation

struct TopicSection: Identifiable {
    let id = UUID()
    let title: String
    let content: SectionContent
}

struct KeyValuePair: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let topicLink: String?  // title of a topic to navigate to (conditions)
}

enum SectionContent {
    case bullets([String])
    case steps([String])
    case keyValue([KeyValuePair])
    case drugTable([DrugEntry])
    case imageGallery([ImageEntry])
}

struct ImageEntry: Identifiable {
    let id = UUID()
    let assetName: String   // name in Assets.xcassets
    let caption: String
    let description: String
}

struct DrugEntry: Identifiable {
    let id = UUID()
    let name: String
    let dose: String
    let route: String
    let contraindications: String
    let notes: String
}
