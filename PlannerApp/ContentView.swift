import SwiftUI
import SwiftData

enum SortMode: String, CaseIterable, Identifiable {
    case manual
    case latest
    case status

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: return "Manual Order"
        case .latest: return "Latest Entry"
        case .status: return "Status"
        }
    }

    var systemImage: String {
        switch self {
        case .manual: return "line.3.horizontal"
        case .latest: return "clock"
        case .status: return "circle.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var projects: [Project]

    @State private var selectedProjectID: PersistentIdentifier?
    @State private var sortMode: SortMode = .latest
    @State private var searchText = ""

    private var filteredProjects: [Project] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return projects }
        return projects.filter { project in
            project.name.localizedCaseInsensitiveContains(query)
                || project.messages.contains { $0.text.localizedCaseInsensitiveContains(query) }
        }
    }

    private var orderedProjects: [Project] {
        switch sortMode {
        case .manual:
            return filteredProjects.sorted { $0.orderIndex < $1.orderIndex }
        case .latest:
            return filteredProjects.sorted { $0.lastUpdated > $1.lastUpdated }
        case .status:
            return filteredProjects.sorted {
                if $0.status.sortRank != $1.status.sortRank {
                    return $0.status.sortRank < $1.status.sortRank
                }
                return $0.lastUpdated > $1.lastUpdated
            }
        }
    }

    private var selectedProject: Project? {
        guard let id = selectedProjectID else { return nil }
        return projects.first { $0.persistentModelID == id }
    }

    var body: some View {
        NavigationSplitView {
            ProjectSidebar(
                projects: orderedProjects,
                sortMode: $sortMode,
                selectedProjectID: $selectedProjectID,
                searchText: searchText
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 420)
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView(
                    "No Project Selected",
                    systemImage: "square.stack.3d.up",
                    description: Text("Select a project on the left to see its history.")
                )
            }
        }
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Search titles and updates"
        )
        .onAppear(perform: seedIfNeeded)
    }

    private func seedIfNeeded() {
        guard projects.isEmpty else { return }

        let samples: [(String, ProjectStatus, [(String, TimeInterval)])] = [
            ("Website Redesign", .onTrack, [
                ("Kicked off the project and gathered initial requirements.", -86400 * 6),
                ("Wireframes approved by stakeholders.", -86400 * 3),
                ("Homepage prototype is ready for review.", -3600 * 4)
            ]),
            ("Mobile App Launch", .atRisk, [
                ("Backend API integration started.", -86400 * 5),
                ("Hit a blocker with push notifications on iOS.", -86400 * 2),
                ("Still waiting on the App Store provisioning profile.", -3600 * 20)
            ]),
            ("Q3 Budget Review", .blocked, [
                ("Requested updated numbers from finance.", -86400 * 4),
                ("Finance is out until next week — review is on hold.", -86400 * 1)
            ]),
            ("Onboarding Docs", .completed, [
                ("Drafted the new hire checklist.", -86400 * 10),
                ("Published the docs to the internal wiki.", -86400 * 7)
            ])
        ]

        // title, completed?
        let todoSamples: [String: [(String, Bool)]] = [
            "Website Redesign": [
                ("Audit existing pages", true),
                ("Finalize color palette", false),
                ("Build component library", false),
                ("Review with stakeholders", false)
            ],
            "Mobile App Launch": [
                ("Set up CI pipeline", true),
                ("Fix push notifications", false),
                ("Submit for App Store review", false)
            ],
            "Q3 Budget Review": [
                ("Collect department numbers", false),
                ("Draft summary deck", false)
            ],
            "Onboarding Docs": [
                ("Write new-hire checklist", true),
                ("Publish to internal wiki", true)
            ]
        ]

        for (index, sample) in samples.enumerated() {
            let project = Project(name: sample.0, status: sample.1, orderIndex: index)
            context.insert(project)
            for entry in sample.2 {
                let message = Message(text: entry.0, timestamp: Date().addingTimeInterval(entry.1))
                message.project = project
                context.insert(message)
            }
            for (todoIndex, todo) in (todoSamples[sample.0] ?? []).enumerated() {
                let item = TodoItem(title: todo.0, orderIndex: todoIndex)
                item.project = project
                if todo.1 {
                    item.isCompleted = true
                    item.completedAt = Date().addingTimeInterval(Double(-todoIndex) * 3600 - 7200)
                }
                context.insert(item)
            }
        }
    }
}
