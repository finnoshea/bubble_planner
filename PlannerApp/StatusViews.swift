import SwiftUI

/// Single source of truth for how a project status is rendered as a colored dot,
/// so the sidebar, detail header, and sheets always match exactly.
struct StatusDot: View {
    let status: ProjectStatus
    var size: CGFloat = 11

    var body: some View {
        Circle()
            .fill(status.color.gradient)
            .frame(width: size, height: size)
    }
}

extension ProjectStatus {
    /// A pre-rasterized colored dot. macOS renders SF Symbols (and many vector
    /// views) inside menus as template images tinted by the accent color, which
    /// strips per-status colors. A bitmap rendered via `ImageRenderer` is not a
    /// template, so the true status color survives in the menu.
    @MainActor
    var swatchImage: Image {
        let renderer = ImageRenderer(content: StatusDot(status: self).padding(1))
        renderer.scale = 2
        if let nsImage = renderer.nsImage {
            nsImage.isTemplate = false
            return Image(nsImage: nsImage).renderingMode(.original)
        }
        return Image(systemName: "circle.fill")
    }
}

/// A menu for picking a project status. Each item shows the status color so the
/// menu matches the colored dots in the sidebar, not just the names.
struct StatusMenu: View {
    @Binding var selection: ProjectStatus

    var body: some View {
        HStack(spacing: 6) {
            // Standalone indicator: a Menu's label is forced to a monochrome
            // control color, so the colored dot must live outside the label.
            // The original-rendered bitmap keeps its true color in the toolbar.
            selection.swatchImage
                .resizable()
                .frame(width: 11, height: 11)
                .padding(.leading, 11)
            Menu {
                ForEach(ProjectStatus.allCases) { status in
                    Button {
                        selection = status
                    } label: {
                        Label {
                            Text(status.rawValue)
                        } icon: {
                            status.swatchImage
                        }
                    }
                }
            } label: {
                Text(selection.rawValue)
            }
            .fixedSize()
        }
    }
}
