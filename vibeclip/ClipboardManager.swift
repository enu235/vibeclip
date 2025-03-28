import Foundation
import AppKit
import SwiftUI

class ClipboardManager: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    private let maxItems = 10
    private var lastChangeCount: Int = 0
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if let text = pasteboard.string(forType: .string) {
            addItem(type: .text, content: text)
        } else if let image = pasteboard.data(forType: .tiff) {
            // For images, we'll store a base64 representation
            let base64String = image.base64EncodedString()
            addItem(type: .image, content: base64String)
        }
    }
    
    private func addItem(type: ClipboardItemType, content: String) {
        let newItem = ClipboardItem(type: type, content: content)
        
        DispatchQueue.main.async {
            self.items.insert(newItem, at: 0)
            if self.items.count > self.maxItems {
                self.items.removeLast()
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
        }
    }
} 