import SwiftUI
import SwiftData

struct TodoPanel: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Project

    @State private var draft = ""
    @FocusState private var addFocused: Bool

    @State private var pendingDeletion: [TodoItem] = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VSplitView {
            activeSection
                .frame(minHeight: 160, idealHeight: 360)
            completedSection
                .frame(minHeight: 120, idealHeight: 200)
        }
        .frame(minWidth: 240)
        .confirmationDialog(
            deletionTitle,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: confirmDeletion)
            Button("Cancel", role: .cancel) { pendingDeletion = [] }
        } message: {
            Text("Deletions are permanent and can't be undone.")
        }
    }

    // MARK: - Active (top)

    private var activeSection: some View {
        VStack(spacing: 0) {
            sectionHeader("To-Do", count: project.activeTodos.count)

            List {
                ForEach(project.activeTodos) { item in
                    ActiveTodoRow(
                        item: item,
                        onComplete: { complete(item) },
                        onDelete: { requestDelete(item) }
                    )
                }
                .onMove(perform: moveActive)
                .onDelete(perform: requestDeleteActive)
            }
            .listStyle(.inset)
            .overlay {
                if project.activeTodos.isEmpty {
                    ContentUnavailableView(
                        "No Active Items",
                        systemImage: "checklist",
                        description: Text("Add a to-do below.")
                    )
                }
            }

            Divider()
            addRow
        }
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.tertiary)
            TextField("Add a to-do…", text: $draft)
                .textFieldStyle(.plain)
                .focused($addFocused)
                .onSubmit(addTodo)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.bar)
    }

    // MARK: - Completed (bottom)

    private var completedSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Completed", count: project.completedTodos.count)

            List {
                ForEach(project.completedTodos) { item in
                    CompletedTodoRow(
                        item: item,
                        onReactivate: { reactivate(item) },
                        onDelete: { requestDelete(item) }
                    )
                }
                .onDelete(perform: requestDeleteCompleted)
            }
            .listStyle(.inset)
            .overlay {
                if project.completedTodos.isEmpty {
                    ContentUnavailableView(
                        "Nothing Completed",
                        systemImage: "checkmark.circle",
                        description: Text("Completed items appear here.")
                    )
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Capsule().fill(.quaternary))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Actions

    private func addTodo() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = (project.activeTodos.map(\.orderIndex).max() ?? -1) + 1
        let item = TodoItem(title: trimmed, orderIndex: nextIndex)
        item.project = project
        context.insert(item)
        draft = ""
        addFocused = true
    }

    private func complete(_ item: TodoItem) {
        item.isCompleted = true
        item.completedAt = Date()
    }

    private func reactivate(_ item: TodoItem) {
        item.isCompleted = false
        item.completedAt = nil
        item.orderIndex = (project.activeTodos.map(\.orderIndex).max() ?? -1) + 1
    }

    private func moveActive(from source: IndexSet, to destination: Int) {
        var items = project.activeTodos
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.orderIndex = index
        }
    }

    private var deletionTitle: String {
        if pendingDeletion.count == 1 {
            return "Delete \u{201C}\(pendingDeletion[0].title)\u{201D}?"
        }
        return "Delete \(pendingDeletion.count) items?"
    }

    private func requestDelete(_ item: TodoItem) {
        pendingDeletion = [item]
        showingDeleteConfirmation = true
    }

    private func requestDeleteActive(at offsets: IndexSet) {
        let items = project.activeTodos
        pendingDeletion = offsets.map { items[$0] }
        showingDeleteConfirmation = true
    }

    private func requestDeleteCompleted(at offsets: IndexSet) {
        let items = project.completedTodos
        pendingDeletion = offsets.map { items[$0] }
        showingDeleteConfirmation = true
    }

    private func confirmDeletion() {
        for item in pendingDeletion {
            context.delete(item)
        }
        pendingDeletion = []
    }
}

private struct ActiveTodoRow: View {
    @Bindable var item: TodoItem
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Mark complete")

            Text(item.title)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct CompletedTodoRow: View {
    @Bindable var item: TodoItem
    let onReactivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Button(action: onReactivate) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .help("Reactivate")

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let completedAt = item.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
