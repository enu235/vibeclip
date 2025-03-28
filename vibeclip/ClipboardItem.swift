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
    
    var preview: String {
        switch type {
        case .text:
            return String(content.prefix(50)) + (content.count > 50 ? "..." : "")
        case .image:
            return "Image"
        case .url:
            return content
        case .rtf:
            return "Rich Text"
        }
    }
    
    var icon: String {
        switch type {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .url:
            return "link"
        case .rtf:
            return "doc.richtext"
        }
    }
}

enum ClipboardItemType: String, Codable, Hashable {
    case text
    case image
    case url
    case rtf
} 