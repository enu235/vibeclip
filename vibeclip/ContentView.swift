//
//  ContentView.swift
//  vibeclip
//
//  Created by Allan Miller on 3/27/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var selectedItem: ClipboardItem?
    
    var body: some View {
        NavigationView {
            List(selection: $selectedItem) {
                ForEach(clipboardManager.items) { item in
                    ClipboardItemRow(item: item)
                }
                    .contextMenu {
                        Button("Copy to Clipboard") {
                            clipboardManager.copyToClipboard(item)
                        }
                    }
            }
            .navigationTitle("Clipboard History")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: clearClipboard) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    private func clearClipboard() {
        NSPasteboard.general.clearContents()
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack {
            Image(systemName: item.type == .text ? "doc.text" : "photo")
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(item.type == .text ? String(item.content.prefix(50)) : "Image")
                    .lineLimit(1)
                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardManager())
}
