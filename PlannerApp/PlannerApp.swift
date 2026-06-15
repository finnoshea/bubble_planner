import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .modelContainer(for: [Project.self, Message.self, TodoItem.self])
        .commands {
            SidebarCommands()
            CommandGroup(after: .toolbar) {
                Picker("Appearance", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.systemImage).tag(mode)
                    }
                }
                Divider()
            }
        }

        Settings {
            SettingsView()
        }
    }
}
