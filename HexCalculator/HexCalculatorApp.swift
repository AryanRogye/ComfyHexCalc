//
//  HexCalculatorApp.swift
//  HexCalculator
//
//  Created by Aryan Rogye on 2/28/26.
//

import SwiftUI
import AppKit

@main
struct HexCalculatorApp: App {
    init() {
        let show = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true
        NSApplication.shared.setActivationPolicy(show ? .regular : .accessory)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Float on Top") {
                    NotificationCenter.default.post(name: .hexFloatOnTopOn, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .option])

                Button("Stop Floating") {
                    NotificationCenter.default.post(name: .hexFloatOnTopOff, object: nil)
                }

                Button("Toggle Float on Top") {
                    NotificationCenter.default.post(name: .hexFloatOnTopToggle, object: nil)
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @AppStorage("showDockIcon") private var showDockIcon = true

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show in Dock", isOn: $showDockIcon)
                    .onChange(of: showDockIcon) { _, newValue in
                        updateDockIcon(show: newValue)
                    }

                Text("Disabling this will hide the app from the Dock and Application Switcher (Cmd+Tab).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .frame(width: 400, height: 120)
    }

    private func updateDockIcon(show: Bool) {
        NSApplication.shared.setActivationPolicy(show ? .regular : .accessory)
        if show {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
