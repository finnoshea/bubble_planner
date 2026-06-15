import SwiftUI
import SwiftData

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case blocked = "Blocked"
    case atRisk = "At Risk"
    case onTrack = "On Track"
    case deprioritized = "Deprioritized"
    case notStarted = "Not Started"
    case completed = "Completed"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blocked: return .red
        case .atRisk: return .orange
        case .onTrack: return .green
        case .deprioritized: return .purple
        case .notStarted: return .gray
        case .completed: return .blue
        }
    }

    /// Lower rank sorts first when ordering by status/color.
    var sortRank: Int {
        switch self {
        case .blocked: return 0
        case .atRisk: return 1
        case .onTrack: return 2
        case .deprioritized: return 3
        case .notStarted: return 4
        case .completed: return 5
        }
    }
}

@Model
final class Project {
    var name: String
    var statusRaw: String
    var createdAt: Date
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \Message.project)
    var messages: [Message]

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.project)
    var todos: [TodoItem]

    init(name: String, status: ProjectStatus = .notStarted, orderIndex: Int = 0) {
        self.name = name
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.orderIndex = orderIndex
        self.messages = []
        self.todos = []
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp > $1.timestamp }
    }

    var lastMessage: Message? {
        messages.max { $0.timestamp < $1.timestamp }
    }

    var lastUpdated: Date {
        lastMessage?.timestamp ?? createdAt
    }

    /// Active to-dos in their manual (drag) order.
    var activeTodos: [TodoItem] {
        todos.filter { !$0.isCompleted }.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Completed to-dos, most recently completed first.
    var completedTodos: [TodoItem] {
        todos.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
}

@Model
final class Message {
    var text: String
    var timestamp: Date
    var project: Project?

    init(text: String, timestamp: Date = Date()) {
        self.text = text
        self.timestamp = timestamp
    }
}

@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool
    var orderIndex: Int
    var createdAt: Date
    var completedAt: Date?
    var project: Project?

    init(title: String, orderIndex: Int = 0) {
        self.title = title
        self.isCompleted = false
        self.orderIndex = orderIndex
        self.createdAt = Date()
        self.completedAt = nil
    }
}
