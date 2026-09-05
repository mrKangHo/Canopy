import SwiftUI

@main
struct CanopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // The real window and its content are entirely AppKit-managed
    // (MainWindowController, wired up in AppDelegate) so the status item can
    // show/hide a single persistent window like a normal app. This Scene
    // only exists to satisfy SwiftUI's App protocol — it never appears.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
