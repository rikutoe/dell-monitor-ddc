import AppKit
import SwiftUI

/// Floating NSPanel for Tahoe-style OSD display.
final class OSDWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 40),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: true
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
    }

    func show(kind: OSDKind = .brightness, value: Int, maxValue: Int) {
        let hostView = NSHostingView(rootView: OSDView(kind: kind, value: value, maxValue: maxValue))
        hostView.frame = NSRect(x: 0, y: 0, width: 200, height: 40)
        contentView = hostView

        positionTopRight()
        orderFrontRegardless()
        alphaValue = 1.0
    }

    func fadeOut(duration: TimeInterval = 0.3) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }

    private func positionTopRight() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - frame.width - 20
        let y = screenFrame.maxY - frame.height - 12
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
