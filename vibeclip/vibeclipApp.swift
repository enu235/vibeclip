//
//  vibeclipApp.swift
//  vibeclip
//
//  Created by Allan Miller on 3/27/25.
//

import SwiftUI

@main
struct vibeclipApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
