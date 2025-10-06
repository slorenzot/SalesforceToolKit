import SwiftUI
import AppKit

class KeyMonitor: ObservableObject {
    @Published var altKeyPressed = false
    private var monitor: Any?

    init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.altKeyPressed = event.modifierFlags.contains(.option)
            return event
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
