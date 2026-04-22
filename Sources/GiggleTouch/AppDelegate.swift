import AppKit
import AVFoundation
import CoreGraphics

@objc class AppDelegate: NSObject, NSApplicationDelegate, AVAudioPlayerDelegate {
    var statusItem: NSStatusItem!
    var eventTap: CFMachPort?
    var eventTapSource: CFRunLoopSource?
    var player: AVAudioPlayer?
    var giggleSounds: [URL] = []
    var lastGiggleTime: Date = .distantPast
    var isEnabled = true
    var lastStatusMessage = "Starting up..."

    let giggleCooldown: TimeInterval = 0.75

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadGiggleSounds()
        setupMenuBar()
        requestPermissionsAndMonitor()
    }

    func loadGiggleSounds() {
        let candidateDirectories = [
            Bundle.main.resourceURL?.appendingPathComponent("giggles"),
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("giggles")
        ].compactMap { $0 }

        for directory in candidateDirectories {
            let sounds = (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ))?.filter {
                ["mp3", "wav", "aiff", "m4a"].contains($0.pathExtension.lowercased())
            }.sorted {
                $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
            } ?? []

            if !sounds.isEmpty {
                giggleSounds = sounds
                return
            }
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        refreshMenuBar()
    }

    func refreshMenuBar() {
        if let button = statusItem.button {
            button.title = isEnabled ? "😄" : "😶"
        }

        let menu = NSMenu()

        let header = NSMenuItem(
            title: isEnabled ? "GiggleTouch: ON (\(giggleSounds.count) sounds)" : "GiggleTouch: OFF (\(giggleSounds.count) sounds)",
            action: nil,
            keyEquivalent: ""
        )
        header.isEnabled = false
        menu.addItem(header)

        let status = NSMenuItem(title: lastStatusMessage, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: isEnabled ? "Disable" : "Enable",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Test Giggle",
            action: #selector(testGiggle),
            keyEquivalent: "t"
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit GiggleTouch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    @objc func toggleEnabled() {
        isEnabled.toggle()
        refreshMenuBar()
    }

    @objc func testGiggle() {
        updateStatus("Manual test")
        playRandomGiggle()
    }

    func requestPermissionsAndMonitor() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessibilityGranted = AXIsProcessTrustedWithOptions(opts)

        // Start the event tap immediately; Input Monitoring is the real requirement for scroll capture.
        startMonitoring()

        if accessibilityGranted {
            updateStatus("Listening for trackpad scrolls")
        } else {
            updateStatus("Listening... add Accessibility if prompted")
        }
    }

    func startMonitoring() {
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard type == .scrollWheel,
                  let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
            appDelegate.handleScrollEvent(event)
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            updateStatus("Failed to create event tap")
            return
        }

        eventTap = tap
        eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let eventTapSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func handleScrollEvent(_ event: CGEvent) {
        guard isEnabled else { return }
        guard meaningfulScroll(for: event) else { return }
        guard shouldGiggle(for: event) else {
            updateStatus("Ignored \(describe(event))")
            return
        }
        guard player?.isPlaying != true else {
            updateStatus("Giggle already playing")
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastGiggleTime) >= giggleCooldown else {
            updateStatus("Cooldown \(describe(event))")
            return
        }
        lastGiggleTime = now

        updateStatus("Stroke \(describe(event))")
        playRandomGiggle()
    }

    func shouldGiggle(for event: CGEvent) -> Bool {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) == 1
        let deltaY = abs(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1))
        let deltaX = abs(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2))
        let magnitude = max(deltaX, deltaY)
        return isContinuous && magnitude > 0.1
    }

    func meaningfulScroll(for event: CGEvent) -> Bool {
        let deltaY = abs(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1))
        let deltaX = abs(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2))
        return max(deltaX, deltaY) > 0.1
    }

    func playRandomGiggle() {
        guard !giggleSounds.isEmpty else { return }

        let url = giggleSounds.randomElement()!

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
            updateStatus("Playing \(url.lastPathComponent)")
        } catch {
            updateStatus("Audio fallback beep")
            NSSound.beep()
        }
    }

    func describe(_ event: CGEvent) -> String {
        let deltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        let deltaX = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
        let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) == 1 ? "precise" : "coarse"
        return String(format: "%@ x=%.2f y=%.2f", continuous, deltaX, deltaY)
    }

    func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.lastStatusMessage = message
            self.refreshMenuBar()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateStatus("Listening for trackpad scrolls")
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
            self.eventTapSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }
}
