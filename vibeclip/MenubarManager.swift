import SwiftUI
import AppKit

class MenubarManager: NSObject, ObservableObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let clipboardManager = ClipboardManager()
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.setupStatusItem()
            self.setupPopover()
        }
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
    
    // MARK: - NSPopoverDelegate
    
    func popoverWillShow(_ notification: Notification) {
        statusItem?.button?.highlight(true)
    }
    
    func popoverDidClose(_ notification: Notification) {
        statusItem?.button?.highlight(false)
    }
} 