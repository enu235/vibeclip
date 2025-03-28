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
    @StateObject private var menubarManager = MenubarManager()
    
    init() {
        // Ensure NSApp is initialized before setting activation policy
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
