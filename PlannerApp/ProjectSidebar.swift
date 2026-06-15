import SwiftUI
import SwiftData

struct ProjectSidebar: View {
    @Environment(\.modelContext) private var context

    let projects: [Project]
    @Binding var sortMode: SortMode
    @Binding var selectedProjectID: PersistentIdentifier?
    var searchText: String = ""

    @State private var showingNewProject = false
    @State private var showingDeleteConfirmation = false
    @State private var projectToRename: Project?

    private var selectedProject: Project? {
        guard let id = selectedProjectID else { return nil }
        return projects.first { $0.persistentModelID == id }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        List(selection: $selectedProjectID) {
            if isSearching {
                Section("Search Results") {
                    ForEach(projects) { project in
                        ProjectRow(project: project, searchText: searchText)
                            .tag(project.persistentModelID)
                            .contextMenu { renameButton(project) }
                    }
                    .onDelete(perform: delete)
                }
            } else {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                        .tag(project.persistentModelID)
                        .contextMenu { renameButton(project) }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if isSearching && projects.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
            ToolbarItem {
                Button {
                    showingNewProject = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Project", systemImage: "trash")
                }
                .disabled(selectedProject == nil)
            }
        }
        .safeAreaInset(edge: .bottom) {
            sortFooter
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet { name, status in
                addProject(name: name, status: status)
            }
        }
        .sheet(item: $projectToRename) { project in
            RenameProjectSheet(project: project)
        }
        .confirmationDialog(
            "Delete \u{201C}\(selectedProject?.name ?? "")\u{201D}?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteSelected)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the project and all of its updates. This can't be undone.")
        }
    }

    @ViewBuilder
    private func renameButton(_ project: Project) -> some View {
        Button {
            projectToRename = project
        } label: {
            Label("Rename…", systemImage: "pencil")
        }
    }

    private var sortFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: sortMode.systemImage)
                .foregroundStyle(.secondary)
            Text("Sorted by \(sortMode.label)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func addProject(name: String, status: ProjectStatus) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = (projects.map(\.orderIndex).max() ?? -1) + 1
        let project = Project(name: trimmed, status: status, orderIndex: nextIndex)
        context.insert(project)
        selectedProjectID = project.persistentModelID
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = projects
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, project) in reordered.enumerated() {
            project.orderIndex = index
        }
        // Dragging implies a manual arrangement.
        sortMode = .manual
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            if project.persistentModelID == selectedProjectID {
                selectedProjectID = nil
            }
            context.delete(project)
        }
    }

    private func deleteSelected() {
        guard let project = selectedProject else { return }
        selectedProjectID = nil
        context.delete(project)
    }
}

/// Highlights every case-insensitive occurrence of `query` within `text`.
private func searchHighlighted(_ text: String, query: String) -> AttributedString {
    var attributed = AttributedString(text)
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return attributed }

    var searchStart = attributed.startIndex
    while searchStart < attributed.endIndex,
          let found = attributed[searchStart...].range(of: trimmed, options: .caseInsensitive) {
        attributed[found].backgroundColor = .yellow.opacity(0.5)
        attributed[found].foregroundColor = .primary
        searchStart = found.upperBound
    }
    return attributed
}

struct ProjectRow: View {
    let project: Project
    var searchText: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            StatusDot(status: project.status)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(searchHighlighted(project.name, query: searchText))
                    .font(.headline)
                    .lineLimit(1)
                Text(searchHighlighted(previewText, query: searchText))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(relativeUpdated)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    /// Prefer showing the update that actually matched the search; otherwise the latest.
    private var previewText: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty,
           !(project.lastMessage?.text.localizedCaseInsensitiveContains(query) ?? false),
           let match = project.sortedMessages.first(where: { $0.text.localizedCaseInsensitiveContains(query) }) {
            return match.text
        }
        return project.lastMessage?.text ?? "No updates yet"
    }

    private var relativeUpdated: String {
        let lastUpdated = project.lastUpdated
        let oneWeek: TimeInterval = 7 * 24 * 60 * 60
        if Date().timeIntervalSince(lastUpdated) > oneWeek {
            return lastUpdated.formatted(date: .abbreviated, time: .shortened)
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}

struct RenameProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: Project
    @State private var name: String

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rename Project")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Name").font(.subheadline).foregroundStyle(.secondary)
                TextField("Project name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        project.name = trimmed
        dismiss()
    }
}

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var status: ProjectStatus = .notStarted

    let onCreate: (String, ProjectStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Project")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Name").font(.subheadline).foregroundStyle(.secondary)
                TextField("Project name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Status").font(.subheadline).foregroundStyle(.secondary)
                StatusMenu(selection: $status)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    onCreate(name, status)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
