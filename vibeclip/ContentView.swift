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
    @State private var searchText = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        }
        return clipboardManager.items.filter { item in
            item.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.windowBackgroundColor))
            
            // List of items
            List(filteredItems, selection: $selectedItem) { item in
                ClipboardItemRow(item: item)
                    .contextMenu {
                        Button("Copy to Clipboard") {
                            clipboardManager.copyToClipboard(item)
                        }
                        Button("Delete", role: .destructive) {
                            clipboardManager.deleteItem(item)
                        }
                    }
            }
            
            // Bottom toolbar
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    clipboardManager.clearHistory()
                }) {
                    Label("Clear History", systemImage: "trash")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
        }
        .frame(width: 480, height: 300)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
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
