//
//  ICSMultiApp.swift
//  ICSMulti
//
//  Created by seb on 25/03/2026.
//

import SwiftUI

@main
struct ICSMultiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Délégué pour fermer l'app quand la dernière fenêtre est fermée
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
