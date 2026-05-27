import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject private var store: AppStore
    @Query private var scores: [LessonScore]

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 14)]

    private var scoreByName: [String: LessonScore] {
        Dictionary(scores.map { ($0.lessonKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(LessonCatalog.all.enumerated()), id: \.element.id) { index, lesson in
                        LessonCardView(index: index, lesson: lesson, score: scoreByName[lesson.name]) {
                            store.currentLesson = lesson
                            store.autoStartPlay = true
                            store.selectedTab = .play
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
