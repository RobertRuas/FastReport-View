import AppKit

final class UpdateProgressWindow {
    private let panel: NSPanel
    private let statusLabel: NSTextField
    private let progressBar: NSProgressIndicator

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 84),
            styleMask: [.titled, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        statusLabel = NSTextField(labelWithString: "A verificar atualizações…")
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.alignment = .center
        statusLabel.frame = NSRect(x: 16, y: 44, width: 268, height: 18)

        progressBar = NSProgressIndicator(frame: NSRect(x: 16, y: 20, width: 268, height: 14))
        progressBar.style = .bar
        progressBar.isIndeterminate = true
        progressBar.minValue = 0
        progressBar.maxValue = 1
        progressBar.startAnimation(nil)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 84))
        content.addSubview(statusLabel)
        content.addSubview(progressBar)
        panel.contentView = content
        panel.center()
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func close() {
        progressBar.stopAnimation(nil)
        panel.orderOut(nil)
    }

    func setStatus(_ text: String) {
        statusLabel.stringValue = text
    }

    func setIndeterminate(_ indeterminate: Bool) {
        guard progressBar.isIndeterminate != indeterminate else { return }
        progressBar.isIndeterminate = indeterminate
        if indeterminate {
            progressBar.startAnimation(nil)
        } else {
            progressBar.stopAnimation(nil)
        }
    }

    func setProgress(_ fraction: Double) {
        progressBar.doubleValue = min(max(fraction, 0), 1)
    }
}
