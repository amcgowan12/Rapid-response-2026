import SwiftUI

struct FavoritesView: View {
    var favorites = FavoritesManager.shared
    private var loader = DataLoader.shared

    var body: some View {
        List {
            if !loader.isLoaded {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if favorites.favoriteTopics.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "bookmark")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.accent)
                    }

                    VStack(spacing: 6) {
                        Text("No Favorites Yet")
                            .font(.headline)

                        Text("Tap the bookmark icon on any topic to save it here for quick access.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(favorites.favoriteTopics) { topic in
                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                        TopicRow(topic: topic, color: .accentColor)
                    }
                }
                .onDelete { offsets in
                    let topics = favorites.favoriteTopics
                    for index in offsets {
                        favorites.toggle(topics[index].title)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loader.loadIfNeeded()
        }
    }
}
