import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // hide from dock, menu bar only

let delegate = AppDelegate()
app.delegate = delegate
app.run()
