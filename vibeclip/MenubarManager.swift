import SwiftUI
import AppKit
import Carbon // Import Carbon for HotKeys
import CoreGraphics // Import CoreGraphics for event simulation

// Define HotKey constants
private let kPasteHotKeyIdentifier = "com.yourapp.pasteHotKey"
private let kVK_ANSI_V: UInt32 = 0x09

class MenubarManager: NSObject, ObservableObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var pastePopover: NSPopover? // Add popover for paste
    @ObservedObject private var clipboardManager = ClipboardManager()
    
    // Carbon Event HotKey variables
    private var eventHandlerRef: EventHandlerRef? = nil
    private var hotKeyRef: EventHotKeyRef? = nil
    private var selfPtr: UnsafeMutableRawPointer? = nil // Store opaque pointer to self
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.setupStatusItem()
            self.setupPopover()
            self.setupPastePopover() // Setup the new popover
            self.registerPasteHotKey() // Register hotkey
        }
    }
    
    deinit {
        unregisterPasteHotKey()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "VibeClip")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePopover)
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 480, height: 300)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.delegate = self
        
        let contentView = ContentView()
            .environmentObject(clipboardManager)
            .frame(width: 480, height: 300)
        
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func setupPastePopover() {
        pastePopover = NSPopover()
        // TODO: Determine appropriate size later
        pastePopover?.contentSize = NSSize(width: 300, height: 400)
        pastePopover?.behavior = .transient
        pastePopover?.animates = false // Often better for cursor popovers
        pastePopover?.delegate = self // Can potentially share delegate

        // Use the actual PasteContentView
        let pasteContentView = PasteContentView(
            clipboardManager: clipboardManager,
            // Capture self weakly in closures to break potential retain cycle
            onSelect: { [weak self] item in
                guard let self = self else { return }
                self.pasteItem(item) // Call method on valid self
            },
            onCancel: { [weak self] in
                guard let self = self else { return }
                self.closePastePopover() // Call method on valid self
            }
        ).frame(width: 300, height: 400) // Set frame if needed, or let popover size control
        pastePopover?.contentViewController = NSHostingController(rootView: pasteContentView)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    // MARK: - Paste HotKey Handling
    
    private func registerPasteHotKey() {
        print("Registering hotkey...")
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Retain self and store the opaque pointer
        let retainedSelf = Unmanaged.passRetained(self)
        self.selfPtr = retainedSelf.toOpaque()
        
        guard InstallEventHandler(GetApplicationEventTarget(), { (handlerRef, eventRef, userData) -> OSStatus in
            // Safely get self back from userData
            guard let userData = userData else {
                print("[Error] Hotkey handler called with nil userData")
                return OSStatus(eventNotHandledErr)
            }
            let manager = Unmanaged<MenubarManager>.fromOpaque(userData).takeUnretainedValue()
            
            // guard let manager = userData?.assumingMemoryBound(to: MenubarManager.self).pointee else {
            //     print("[Error] Failed to get MenubarManager instance in hotkey handler")
            //     return OSStatus(eventNotHandledErr)
            // }
            return manager.handleHotKeyEvent(eventRef)
        }, 1, &eventType, self.selfPtr, &eventHandlerRef) == noErr else { // Pass the stored pointer
            print("Error installing event handler")
            // Release self if handler installation failed
            retainedSelf.release()
            self.selfPtr = nil
            return
        }
        
        let hotKeyID = EventHotKeyID(signature: kPasteHotKeyIdentifier.fourCharStringCode, id: 1)
        let modifierFlags: UInt32 = UInt32(cmdKey | controlKey) // CMD + CTRL
        let keyCode = kVK_ANSI_V
        
        guard RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef) == noErr else {
            print("Error registering hotkey CMD+CTRL+V")
            return
        }
        print("Hotkey CMD+CTRL+V registered successfully.")
    }
    
    private func unregisterPasteHotKey() {
        print("Unregistering hotkey...")
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        // Release self when handler is removed
        if let pointer = self.selfPtr {
            Unmanaged<MenubarManager>.fromOpaque(pointer).release()
            self.selfPtr = nil
        }
        print("Hotkey unregistered.")
    }
    
    private func handleHotKeyEvent(_ eventRef: EventRef?) -> OSStatus {
        guard let eventRef = eventRef else { return OSStatus(eventNotHandledErr) }
        
        var hotKeyID = EventHotKeyID()
        guard GetEventParameter(eventRef,
                                OSType(kEventParamDirectObject),
                                OSType(typeEventHotKeyID),
                                nil,
                                MemoryLayout<EventHotKeyID>.size,
                                nil,
                                &hotKeyID) == noErr else {
            return OSStatus(eventNotHandledErr)
        }
        
        guard hotKeyID.signature == kPasteHotKeyIdentifier.fourCharStringCode, hotKeyID.id == 1 else {
            return OSStatus(eventNotHandledErr) // Not our hotkey
        }
        
        print("Paste Hotkey CMD+CTRL+V Pressed!")
        // Call the function to show the popover
        DispatchQueue.main.async { // Ensure UI updates on main thread -- RE-ENABLED
            print("Dispatching showPastePopoverAtCursor to main thread") // Added log
            self.showPastePopoverAtCursor()
        }
        // print("!!! Dispatch block COMMENTED OUT !!!") // Add log
        
        return noErr // We handled it
    }
    
    private func showPastePopoverAtCursor() {
        print("-> Entered showPastePopoverAtCursor") // Added log
        
        // Ensure pastePopover exists
        guard let pastePopover = pastePopover else {
            print("[Error] Failed guard check: pastePopover is nil") // Added log
            return
        }

        // --- REVERT TO BUTTON POSITIONING ONLY --- 
        print("Showing paste popover relative to button for stability.")
        guard let button = statusItem?.button else {
            print("[Error] Cannot show popover: statusItem?.button is nil")
            return
        }
        if pastePopover.isShown {
            print("Popover already shown, performing close.")
            pastePopover.performClose(nil)
        } else {
            print("Calling pastePopover.show(...) relative to button")
            pastePopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            print("Finished pastePopover.show(...) call (button)")
        }
        // --- END REVERT ---
        
        /* --- Positioning Window Logic (REMOVED FOR STABILITY) ---
        // Get mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation
        print("Mouse location: \(mouseLocation)")

        // Close any existing positioning window first
        // positioningWindow?.close()
        // positioningWindow = nil

        // Create a small, transparent, borderless window at the mouse location
        // ... (window creation code removed) ...

        // Ensure the temp window has a content view
        // guard let positioningContentView = positioningWindow?.contentView else {
        //     print("[Error] Could not get contentView of temporary positioning window.")
        //     positioningWindow?.close() // Clean up
        //     positioningWindow = nil
        //     return
        // }

        // print("Showing paste popover relative to temporary window at cursor")
        // Show the popover relative to the bottom-left of the temp window's content view
        // pastePopover.show(relativeTo: positioningContentView.bounds,
        //                    of: positioningContentView,
        //                    preferredEdge: .minY)

        // Clean up positioning window IMMEDIATELY after showing
        // print("Cleaning up positioning window immediately after show.")
        // positioningWindow?.close()
        // positioningWindow = nil

        // print("Finished pastePopover.show(...) call and immediate cleanup")
        */
    }

    // MARK: - Action Handlers for Paste Popover
    
    func closePastePopover() {
        print("Closing paste popover programmatically")
        pastePopover?.performClose(nil)
        // positioningWindow cleanup happens in popoverDidClose
    }
    
    func pasteItem(_ item: ClipboardItem) {
        print("Pasting item: \(item.content)") // Restored original log
        // // 1. Update Pasteboard - RE-ENABLED
        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(item.content, forType: .string)
        if !success {
             print("[Error] Failed to set pasteboard string.")
             // Decide if we should still attempt paste/close
        }
        
        // // 2. Close popover (do this BEFORE simulating paste to avoid focus issues)
        // Keep commented - popover closes automatically via .transient behavior
        closePastePopover() // <<< RE-ENABLED
        // print("!!! Popover should close automatically (transient) !!!") // Removed log
        
        // // 3. Simulate CMD+V - Slight delay might be needed - RE-ENABLED
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in // Use weak self
            // Ensure self is still valid when the closure executes
            guard let self = self else {
                print("[Warning] MenubarManager deallocated before simulateCommandV could run.")
                return
            }
             self.simulateCommandV() // <<< RE-ENABLED
             // print("!!! Skipping simulateCommandV() call for testing !!!") // Removed log
        }
    }
    
    private func simulateCommandV() {
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            print("[Error] Failed to create event source for paste simulation")
            return
        }

        let keyVDown = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyVDown?.flags = .maskCommand

        let keyVUp = CGEvent(keyboardEventSource: eventSource, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyVUp?.flags = .maskCommand

        if let down = keyVDown, let up = keyVUp {
            down.post(tap: .cgSessionEventTap)
            up.post(tap: .cgSessionEventTap)
            print("Simulated CMD+V")
        } else {
            print("[Error] Failed to create CGEvent for CMD+V simulation")
        }
    }

    // MARK: - NSPopoverDelegate
    
    func popoverWillShow(_ notification: Notification) {
        // Check which popover is showing
        guard let popover = notification.object as? NSPopover else { return }
        if popover == self.popover {
            // Highlight for main popover
            statusItem?.button?.highlight(true)
        }
        // No highlight needed for paste popover
    }
    
    func popoverDidClose(_ notification: Notification) {
        guard let popover = notification.object as? NSPopover else { return }
        // Only unhighlight if it was the main popover that closed
        if popover == self.popover {
            statusItem?.button?.highlight(false)
        }
        // Add logic here later if needed for the paste popover closing,
        else if popover == self.pastePopover {
            // Paste popover closed. No positioningWindow cleanup needed anymore.
            print("Paste popover closed.") 
            // positioningWindow?.close() // REMOVED
            // positioningWindow = nil    // REMOVED
        }
    }
}

// Helper extension for FourCharCode
extension String {
    var fourCharStringCode: FourCharCode {
        return self.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
    }
} 