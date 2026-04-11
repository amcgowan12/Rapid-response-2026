import SwiftUI

@Observable
final class FavoritesManager {
    static let shared = FavoritesManager()

    private let key = "favoriteTopicTitles"
    private(set) var favoriteTitles: Set<String>

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: key) ?? []
        favoriteTitles = Set(saved)
    }
    func isFavorite(_ title: String) -> Bool {
        favoriteTitles.contains(title)
    }

    func toggle(_ title: String) {
        if favoriteTitles.contains(title) {
            favoriteTitles.remove(title)
        } else {
            favoriteTitles.insert(title)
        }
        save()
    }

    /// Returns matching Topic objects from both data sources
    var favoriteTopics: [Topic] {
        let loader = DataLoader.shared
        let allTopics = (loader.conditionSystems + loader.symptomSystems)
            .flatMap { $0.topics }
        var seen = Set<String>()
        return allTopics.filter { topic in
            guard favoriteTitles.contains(topic.title), !seen.contains(topic.title) else { return false }
            seen.insert(topic.title)
            return true
        }
    }

    private func save() {
        UserDefaults.standard.set(Array(favoriteTitles), forKey: key)
    }
}
