# BubblePlanner

A native macOS app for lightweight project record-keeping.

Each project keeps a running log of timestamped updates and its own to-do list, so you can track what's happening across everything you're working on at a glance.

## Features

- **Project list** with color-coded status (Blocked, At Risk, On Track, Deprioritized, Not Started, Completed), sortable by manual order, latest activity, or status.
- **Update log** per project — add timestamped notes, shown newest-first.
- **To-do list** per project, split into active and completed items, with drag-to-reorder and completion timestamps.
- **Search** across all project titles and updates, with matches highlighted.
- **Rename** projects via right-click; **delete** with confirmation.
- **Appearance** preference: Light, Dark, or follow the System setting.

Data is stored locally with SwiftData.

## Requirements

- macOS 14.0 or later
- Xcode 16 or later (Swift 5)

## Building with Xcode

1. Open `PlannerApp.xcodeproj` in Xcode.
2. Select the **PlannerApp** scheme and a **My Mac** run destination.
3. Press **Run** (`⌘R`) to build and launch.

### Building a standalone app

To produce a shareable `.app`:

1. Set the build configuration to **Release** (Product → Scheme → Edit Scheme → Run → Build Configuration), or use **Product → Archive**.
2. With Archive: in the Organizer, select the archive → **Distribute App** → **Custom** → **Copy App**.

> The app is signed ad-hoc for local use only. When shared to another Mac, Gatekeeper will block it on first launch — the recipient can right-click the app and choose **Open**, or run `xattr -dr com.apple.quarantine /path/to/BubblePlanner.app`. Distributing without warnings requires a paid Apple Developer account to sign with a Developer ID and notarize.
