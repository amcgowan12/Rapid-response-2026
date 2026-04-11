import SwiftUI

struct OrganSystem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String        // SF Symbol name, e.g. "heart.fill"
    let color: Color
    let topics: [Topic]
}
