import Foundation

@MainActor
final class GoalStore: ObservableObject {
    @Published private(set) var goals: [Goal] = []

    private let persistence = GoalsPersistence()

    init() {
        load()
    }

    func load() {
        do {
            if let loaded = try persistence.loadGoals() {
                goals = loaded.sorted(by: { $0.createdAt > $1.createdAt })
            } else {
                goals = []
            }
        } catch {
            goals = []
        }
    }

    func add(_ goal: Goal) {
        goals.insert(goal, at: 0)
        persistBestEffort()
    }

    func update(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx] = goal
        goals.sort(by: { $0.createdAt > $1.createdAt })
        persistBestEffort()
    }

    func delete(_ goal: Goal) {
        goals.removeAll(where: { $0.id == goal.id })
        persistBestEffort()
    }

    func toggleActive(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx].isActive.toggle()
        persistBestEffort()
    }

    private func persistBestEffort() {
        do { try persistence.saveGoals(goals) } catch { /* best-effort */ }
    }
}

