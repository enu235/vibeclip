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
        checkClipboard()
        
        // Set up timer for monitoring
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
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let imageData = Data(base64Encoded: item.content) {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case .url:
            pasteboard.setString(item.content, forType: .URL)
        case .rtf:
            if let rtfData = item.content.data(using: .utf8) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
        }
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