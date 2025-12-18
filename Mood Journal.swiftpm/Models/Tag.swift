import Foundation

enum Tag: String, CaseIterable, Codable, Hashable, Identifiable {
    case school
    case work
    case friends
    case family
    case exercise
    case sleep
    case nutrition
    case creativity
    case outdoors
    case anxious
    case grateful

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .school: return "School"
        case .work: return "Work"
        case .friends: return "Friends"
        case .family: return "Family"
        case .exercise: return "Exercise"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        case .creativity: return "Creativity"
        case .outdoors: return "Outdoors"
        case .anxious: return "Anxious"
        case .grateful: return "Grateful"
        }
    }
}


