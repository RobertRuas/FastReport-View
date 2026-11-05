import AppKit
import SwiftUI

final class MainWindowController: NSObject, NSWindowDelegate {
    private let window: NSWindow
    let state = AppState()

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 510),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = "FastReport View"
        window.contentMinSize = NSSize(width: 750, height: 510)
        window.contentView = NSHostingView(rootView: MainWindowView(state: state))
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        state.windowOrigin = window.frame.origin
    }

    func windowDidMove(_ notification: Notification) {
        state.windowOrigin = window.frame.origin
    }

    func windowDidResize(_ notification: Notification) {
        state.windowOrigin = window.frame.origin
    }
}
