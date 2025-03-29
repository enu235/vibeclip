import Foundation
import AppKit
import SwiftUI

class ClipboardManager: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    private let maxItems = 20
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        // Initial check
        // checkClipboard() // REMOVED: Avoid calling synchronously during init
        
        // Set up timer for monitoring
        // The timer will perform the first check shortly after init.
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Check for text
        if let text = pasteboard.string(forType: .string) {
            addItem(type: .text, content: text)
        }
        // Check for image
        else if let image = pasteboard.data(forType: .tiff) {
            let base64String = image.base64EncodedString()
            addItem(type: .image, content: base64String)
        }
        // Check for URL
        else if let url = pasteboard.string(forType: .URL) {
            addItem(type: .url, content: url)
        }
        // Check for RTF
        else if let rtf = pasteboard.data(forType: .rtf) {
            if let rtfString = String(data: rtf, encoding: .utf8) {
                addItem(type: .rtf, content: rtfString)
            }
        }
    }
    
    private func addItem(type: ClipboardItemType, content: String) {
        let newItem = ClipboardItem(type: type, content: content)
        
        DispatchQueue.main.async {
            // Check for duplicates
            if !self.items.contains(where: { $0.content == content }) {
                self.items.insert(newItem, at: 0)
                if self.items.count > self.maxItems {
                    self.items.removeLast()
                }
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        print("Attempting to copy original item: \(item.id) - Type: \(item.type)")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var success = false
        switch item.type {
        case .text:
            success = pasteboard.setString(item.content, forType: .string)
        case .image:
            if let imageData = Data(base64Encoded: item.content) {
                success = pasteboard.setData(imageData, forType: .tiff)
            } else {
                print("Error decoding base64 image data for item \(item.id)")
            }
        case .url:
            success = pasteboard.setString(item.content, forType: .URL)
        case .rtf:
            if let rtfData = item.content.data(using: .utf8) {
                success = pasteboard.setData(rtfData, forType: .rtf)
            } else {
                print("Error encoding RTF data for item \(item.id)")
            }
        }
        print("Copy original item \(item.id) successful: \(success)")
    }
    
    func copyAsPlainText(_ item: ClipboardItem) {
        print("Attempting to copy item as plain text: \(item.id)")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(item.content, forType: .string) // Always copy as plain text
        print("Copy item as plain text \(item.id) successful: \(success)")
    }
    
    func clearHistory() {
        items.removeAll()
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
} 