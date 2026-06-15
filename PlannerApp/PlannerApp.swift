import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, Message.self])
        .commands {
            SidebarCommands()
        }
    }
}
