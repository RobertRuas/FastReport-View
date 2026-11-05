import AppKit

enum WindowFrameDialog {
    static func show(for window: NSWindow) {
        let frame = window.frame

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Ajustar janela"
        alert.informativeText = "Define a largura, altura e posição da janela."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancelar")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 68))

        let widthField = field(label: "Largura", value: frame.width, x: 0, y: 36, in: container)
        let heightField = field(label: "Altura", value: frame.height, x: 130, y: 36, in: container)
        let xField = field(label: "Posição X", value: frame.origin.x, x: 0, y: 0, in: container)
        let yField = field(label: "Posição Y", value: frame.origin.y, x: 130, y: 0, in: container)

        alert.accessoryView = container
        alert.window.initialFirstResponder = widthField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        guard
            let width = Double(widthField.stringValue),
            let height = Double(heightField.stringValue),
            let x = Double(xField.stringValue),
            let y = Double(yField.stringValue),
            width > 0, height > 0
        else { return }

        window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: true)
    }

    @discardableResult
    private static func field(label: String, value: CGFloat, x: CGFloat, y: CGFloat, in container: NSView) -> NSTextField {
        let title = NSTextField(labelWithString: label)
        title.font = .systemFont(ofSize: 11)
        title.textColor = .secondaryLabelColor
        title.frame = NSRect(x: x, y: y + 24, width: 110, height: 16)
        container.addSubview(title)

        let field = NSTextField(frame: NSRect(x: x, y: y, width: 110, height: 22))
        field.stringValue = String(Int(value.rounded()))
        field.alignment = .right
        container.addSubview(field)

        return field
    }
}
