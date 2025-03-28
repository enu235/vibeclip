import Foundation
import AppKit

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: ClipboardItemType
    let content: String
    
    init(type: ClipboardItemType, content: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.content = content
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ClipboardItemType: String, Codable, Hashable {
    case text
    case image
} 