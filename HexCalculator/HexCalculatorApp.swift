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
        TabView {
            // General Settings Tab
            Form {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Show in Dock", isOn: $showDockIcon)
                        .onChange(of: showDockIcon) { newValue in
                            updateDockIcon(show: newValue)
                        }

                    Text("Disabling this will hide the app from the Dock and Application Switcher (Cmd+Tab).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            // About Tab
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hex Calculator")
                            .font(.headline)
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                Text("Developer's Note")
                    .font(.headline)
                    .padding(.top, 4)

                Text("Built out of frustration with standard calculators that default to 64-bit and make low-level OS development (like 16-bit or 32-bit Two's Complement checksums) a nightmare.\n\nThis app is strictly designed to handle exact bit widths and wrap-on-overflow logic accurately for embedded systems and kernel development.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)

                Spacer()
            }
            .padding(20)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 280)
    }

    private func updateDockIcon(show: Bool) {
        NSApplication.shared.setActivationPolicy(show ? .regular : .accessory)
        if show {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
