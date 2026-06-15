import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Project

    @State private var draft = ""
    @FocusState private var composerFocused: Bool

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                messageList
                Divider()
                composer
            }
            .frame(minWidth: 360, idealWidth: 520)

            TodoPanel(project: project)
                .frame(minWidth: 260, idealWidth: 320, maxWidth: 460)
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                statusPicker
            }
        }
    }

    private var messageList: some View {
        ScrollView {
            if project.messages.isEmpty {
                ContentUnavailableView(
                    "No Updates Yet",
                    systemImage: "text.bubble",
                    description: Text("Add the first update for this project below.")
                )
                .padding(.top, 80)
            } else {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(project.sortedMessages) { message in
                        MessageCard(message: message) {
                            context.delete(message)
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Add an update…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.quaternary)
                        )
                )
                .focused($composerFocused)
                .onSubmit(addMessage)

            Button(action: addMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(14)
        .background(.bar)
    }

    private var statusPicker: some View {
        StatusMenu(selection: $project.status)
    }

    private func addMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = Message(text: trimmed)
        message.project = project
        context.insert(message)
        draft = ""
        composerFocused = true
    }
}

struct MessageCard: View {
    let message: Message
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        )
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Update", systemImage: "trash")
            }
        }
    }
}
