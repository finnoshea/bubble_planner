import SwiftUI
import SwiftData

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case blocked = "Blocked"
    case atRisk = "At Risk"
    case onTrack = "On Track"
    case notStarted = "Not Started"
    case completed = "Completed"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blocked: return .red
        case .atRisk: return .orange
        case .onTrack: return .green
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
        case .notStarted: return 3
        case .completed: return 4
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

    init(name: String, status: ProjectStatus = .notStarted, orderIndex: Int = 0) {
        self.name = name
        self.statusRaw = status.rawValue
        self.createdAt = Date()
        self.orderIndex = orderIndex
        self.messages = []
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
