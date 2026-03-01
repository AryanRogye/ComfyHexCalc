//
//  ContentView.swift
//  HexCalculator
//
//  Created by Aryan Rogye on 2/28/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    // MARK: - Enums & Types

    enum BitWidth: Int, CaseIterable, Identifiable {
        case b8 = 8, b16 = 16, b32 = 32, b64 = 64
        var id: Int { rawValue }
        var label: String { "\(rawValue)" }
        var mask: UInt64 {
            rawValue == 64 ? UInt64.max : (UInt64(1) << UInt64(rawValue)) - 1
        }
    }

    enum Operation: String, CaseIterable, Identifiable {
        case add = "+", subtract = "−", and = "AND", or = "OR", xor = "XOR"
        case shiftLeft = "<<", shiftRight = ">>", notA = "NOT", negA = "NEG"
        case checksumOnes = "CHK~", checksumTwos = "CHK-"

        var id: String { rawValue }
        var isUnary: Bool { self == .notA || self == .negA }

        var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "−"
            case .and: return "&"
            case .or: return "|"
            case .xor: return "^"
            case .shiftLeft: return "«"
            case .shiftRight: return "»"
            case .notA: return "~"
            case .negA: return "±"
            case .checksumOnes: return "Σ~"
            case .checksumTwos: return "Σ-"
            }
        }
    }

    enum InputTarget: String, CaseIterable, Identifiable {
        case a = "A", b = "B"
        var id: String { rawValue }
    }

    struct HistoryEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let bitWidth: Int
        let operation: String
        let inputA: String
        let inputB: String
        let resultHex: String
        let resultDecimal: String
        let status: String

        var expression: String {
            inputB.isEmpty ? "\(operation) \(inputA)" : "\(inputA) \(operation) \(inputB)"
        }
    }

    // MARK: - State

    @State private var inputA = ""
    @State private var inputB = ""
    @State private var selectedBitWidth: BitWidth = .b32
    @State private var selectedOperation: Operation = .add
    @State private var wrapOnOverflow = true
    @State private var activeInput: InputTarget = .a
    @State private var alwaysOnTop = false
    @State private var hostWindow: NSWindow?

    @State private var resultHex = "0x00000000"
    @State private var resultDecimal = "0"
    @State private var status = "Ready"
    @State private var keyEventStatus = ""
    @State private var keyEventMonitor: Any?

    @State private var history: [HistoryEntry] = []
    @State private var showSidebar = false

    private let historyKey = "HexCalculator.History"
    private let alwaysOnTopKey = "HexCalculator.AlwaysOnTop"

    // Layout Constants
    private let calculatorWidth: CGFloat = 420
    private let sidebarWidth: CGFloat = 280

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            if showSidebar {
                historySidebar
                    .frame(width: sidebarWidth)
                    .transition(.move(edge: .leading))
            }

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    displaySection

                    Divider().background(Color.white.opacity(0.1))

                    controlsHeader

                    keypadSection
                }
                .padding(20)
            }
            .frame(width: calculatorWidth)
            .background(Color.black)
        }
        .frame(width: showSidebar ? calculatorWidth + sidebarWidth : calculatorWidth, height: 750)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSidebar)
        .background(
            WindowAccessor { window in
                hostWindow = window
                applyWindowLevel()
            }
        )
        .onAppear {
            resultHex = formatHex(0, bits: selectedBitWidth.rawValue)
            alwaysOnTop = UserDefaults.standard.bool(forKey: alwaysOnTopKey)
            loadHistory()
            installKeyEventMonitor()
            applyWindowLevel()
        }
        .onDisappear {
            removeKeyEventMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hexFloatOnTopOn)) { _ in
            setAlwaysOnTop(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .hexFloatOnTopOff)) { _ in
            setAlwaysOnTop(false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .hexFloatOnTopToggle)) { _ in
            toggleAlwaysOnTop()
        }
        .onChange(of: alwaysOnTop) { isOn in
            UserDefaults.standard.set(isOn, forKey: alwaysOnTopKey)
            applyWindowLevel()
        }
    }

    // MARK: - UI Components

    private var displaySection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Target Selection & Mode
            HStack {
                Button(action: {
                    withAnimation {
                        showSidebar.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.title3)
                        .foregroundColor(showSidebar ? .orange : .gray)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(selectedBitWidth.rawValue)-BIT")
                    .font(.caption.bold().monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
            .padding(.bottom, 10)

            // Input A
            VStack(alignment: .trailing, spacing: 2) {
                Text("INPUT A")
                    .font(.caption2.bold())
                    .foregroundColor(activeInput == .a ? .orange : .gray)
                Text(inputA.isEmpty ? "0" : inputA)
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundColor(activeInput == .a ? .white : .gray)
                    .lineLimit(1)
            }
            .onTapGesture { activeInput = .a }

            // Input B
            VStack(alignment: .trailing, spacing: 2) {
                Text("INPUT B")
                    .font(.caption2.bold())
                    .foregroundColor(activeInput == .b ? .orange : .gray)
                    .opacity(selectedOperation.isUnary ? 0.3 : 1.0)
                Text(inputB.isEmpty ? "0" : inputB)
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundColor(activeInput == .b ? .white : .gray)
                    .lineLimit(1)
                    .opacity(selectedOperation.isUnary ? 0.3 : 1.0)
            }
            .onTapGesture { if !selectedOperation.isUnary { activeInput = .b } }

            Spacer(minLength: 10)

            // Main Result
            VStack(alignment: .trailing, spacing: 4) {
                Text(resultHex)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contextMenu {
                        Button("Copy Hex") { copyToClipboard(resultHex) }
                    }

                Text(resultDecimal)
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .contextMenu {
                        Button("Copy Decimal") { copyToClipboard(resultDecimal) }
                    }

                Text(status)
                    .font(.caption2)
                    .foregroundColor(status == "OK" || status == "Ready" ? .green : .orange)

                if !keyEventStatus.isEmpty {
                    Text(keyEventStatus)
                        .font(.caption2.monospaced())
                        .foregroundColor(.yellow)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 20)
        .contentShape(Rectangle())
    }

    private var controlsHeader: some View {
        HStack(spacing: 16) {
            // Bit Width Section
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text("WIDTH")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    ForEach(BitWidth.allCases) { bw in
                        widthButton(bw)
                    }
                }
            }

            Spacer()

            // Wrap Section
            HStack(spacing: 8) {
                Text("WRAP")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)

                Toggle("", isOn: $wrapOnOverflow)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .tint(.orange)
            }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
        .padding(.vertical, 12)
    }

    private func widthButton(_ bitWidth: BitWidth) -> some View {
        Button {
            selectedBitWidth = bitWidth
        } label: {
            Text(bitWidth.label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(selectedBitWidth == bitWidth ? Color.orange : Color.white.opacity(0.14))
                .foregroundColor(selectedBitWidth == bitWidth ? .black : .white)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var keypadSection: some View {
        VStack(spacing: 12) {
            // Hex Digits Row 1
            HStack(spacing: 12) {
                calcButton("A", color: .darkGray) { appendKey("A") }
                calcButton("B", color: .darkGray) { appendKey("B") }
                calcButton("C", color: .darkGray) { appendKey("C") }
                calcButton("CLR", color: .mediumGray, textColor: .black) { clear() }
                calcButton(selectedOperation.symbol, color: .orange) { /* Current Op */ }
            }

            // Hex Digits Row 2
            HStack(spacing: 12) {
                calcButton("D", color: .darkGray) { appendKey("D") }
                calcButton("E", color: .darkGray) { appendKey("E") }
                calcButton("F", color: .darkGray) { appendKey("F") }
                calcButton("7", color: .darkGray) { appendKey("7") }
                calcButton("8", color: .darkGray) { appendKey("8") }
            }

            // Row 3
            HStack(spacing: 12) {
                calcButton("9", color: .darkGray) { appendKey("9") }
                calcButton("4", color: .darkGray) { appendKey("4") }
                calcButton("5", color: .darkGray) { appendKey("5") }
                calcButton("6", color: .darkGray) { appendKey("6") }
                calcButton("1", color: .darkGray) { appendKey("1") }
            }

            // Row 4
            HStack(spacing: 12) {
                calcButton("2", color: .darkGray) { appendKey("2") }
                calcButton("3", color: .darkGray) { appendKey("3") }
                calcButton("0", color: .darkGray) { appendKey("0") }
                calcButton("0x", color: .mediumGray, textColor: .black) { addPrefix() }
                calcButton("⌫", color: .mediumGray, textColor: .black) { backspace() }
            }

            // Operations Grid
            VStack(alignment: .leading, spacing: 4) {
                Text("OPERATIONS")
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
                    .padding(.leading, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Operation.allCases) { op in
                            Button(action: { selectedOperation = op; calculate() }) {
                                Text(op.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedOperation == op ? Color.orange : Color.white.opacity(0.1))
                                    .foregroundColor(selectedOperation == op ? .black : .white)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Action Row
            HStack(spacing: 12) {
                calcButton("SWAP A/B", color: .mediumGray, textColor: .black) {
                    (inputA, inputB) = (inputB, inputA)
                }
                calcButton("=", color: .orange) { calculate() }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func calcButton(_ label: String, color: Color, textColor: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(color)
                .foregroundColor(textColor)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .frame(height: 50)
    }

    private var historySidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Label("History", systemImage: "clock.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    history.removeAll()
                    saveHistory()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.white.opacity(0.05))

            List {
                ForEach(history) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.expression)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.gray)

                        HStack {
                            Text(entry.resultHex)
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.orange)
                            Spacer()
                            Text(entry.resultDecimal)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }

                        Text("\(entry.bitWidth)-BIT • \(entry.timestamp.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        inputA = entry.resultHex
                    }
                }
                .onDelete(perform: deleteHistory)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(Color(white: 0.1))
    }

    // MARK: - Logic Helpers

    private func appendKey(_ key: String) {
        if activeInput == .a {
            inputA += key
        } else {
            inputB += key
        }
    }

    private func backspace() {
        if activeInput == .a {
            if !inputA.isEmpty { inputA.removeLast() }
        } else {
            if !inputB.isEmpty { inputB.removeLast() }
        }
    }

    private func clear() {
        inputA = ""
        inputB = ""
        status = "Ready"
        resultHex = formatHex(0, bits: selectedBitWidth.rawValue)
        resultDecimal = "0"
    }

    private func addPrefix() {
        let current = activeInput == .a ? inputA : inputB
        let normalized = normalizeInputForEditing(current)
        if normalized.isEmpty {
            setActiveInput("0x")
            return
        }

        if !normalized.lowercased().hasPrefix("0x") {
            setActiveInput("0x" + normalized)
        } else {
            setActiveInput(normalized)
        }
    }

    private func handlePaste() {
        if let pasteboardString = NSPasteboard.general.string(forType: .string) {
            if let cleaned = extractHexCandidate(from: pasteboardString) {
                setActiveInput(cleaned)
                status = "Pasted into \(activeInput.rawValue)"
                flashKeyEvent("Paste OK -> \(activeInput.rawValue): \(cleaned)")
            } else {
                status = "No hex value found in pasteboard"
                flashKeyEvent("Paste failed -> no hex token found")
            }
        } else {
            flashKeyEvent("Pasteboard empty")
        }
    }

    private func flashKeyEvent(_ message: String) {
        keyEventStatus = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if keyEventStatus == message {
                keyEventStatus = ""
            }
        }
    }

    private func installKeyEventMonitor() {
        guard keyEventMonitor == nil else { return }
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handleKeyEvent(event) ? nil : event
        }
    }

    private func removeKeyEventMonitor() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let chars = event.charactersIgnoringModifiers ?? ""
        let normalized = chars.uppercased()
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers.contains(.command) && chars.lowercased() == "v" {
            flashKeyEvent("CMD+V detected -> target \(activeInput.rawValue)")
            handlePaste()
            return true
        }

        switch event.keyCode {
        case 126: // Up arrow
            activeInput = .a
            flashKeyEvent("Target -> A")
            return true
        case 125: // Down arrow
            if !selectedOperation.isUnary {
                activeInput = .b
                flashKeyEvent("Target -> B")
            }
            return true
        case 51, 117: // Delete / Forward delete
            backspace()
            return true
        case 36: // Return
            calculate()
            return true
        case 53: // Escape
            clear()
            return true
        default:
            break
        }

        if normalized.count == 1 && "0123456789ABCDEF".contains(normalized) {
            appendKey(normalized)
            return true
        }

        return false
    }

    private func parseHex(_ text: String) -> UInt64? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
        guard !normalized.isEmpty else { return 0 }
        return UInt64(normalized, radix: 16)
    }

    private func setActiveInput(_ value: String) {
        if activeInput == .a {
            inputA = value
        } else {
            inputB = value
        }
    }

    private func normalizeInputForEditing(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "0X", with: "0x")
        value = value.uppercased()

        if value.hasPrefix("0X") {
            value = "0x" + String(value.dropFirst(2))
        }

        return value
    }

    private func extractHexCandidate(from text: String) -> String? {
        let pattern = #"(?i)0x[0-9a-f_]+|[0-9a-f][0-9a-f_]*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let range = NSRange(source.startIndex..., in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              let swiftRange = Range(match.range, in: source) else {
            return nil
        }

        var token = String(source[swiftRange])
        token = token.replacingOccurrences(of: "__", with: "_")
        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        if token.isEmpty { return nil }

        if token.lowercased().hasPrefix("0x") {
            let suffix = token.dropFirst(2).uppercased()
            return suffix.isEmpty ? nil : "0x\(suffix)"
        }

        return token.uppercased()
    }

    private func formatHex(_ value: UInt64, bits: Int) -> String {
        let digits = max(1, bits / 4)
        return String(format: "0x%0\(digits)llX", value)
    }

    private func calculate() {
        let mask = selectedBitWidth.mask
        guard let parsedA = parseHex(inputA) else { status = "Invalid A"; return }

        var parsedB: UInt64 = 0
        if !selectedOperation.isUnary {
            guard let tempB = parseHex(inputB) else { status = "Invalid B"; return }
            parsedB = tempB
        }

        let a = wrapOnOverflow ? (parsedA & mask) : parsedA
        let b = wrapOnOverflow ? (parsedB & mask) : parsedB

        if !wrapOnOverflow && (a > mask || b > mask) {
            status = "Overflow"
            return
        }

        var value: UInt64 = 0
        var flag = "OK"

        switch selectedOperation {
        case .add:
            let raw = a &+ b
            value = raw & mask
            if a > (mask &- b) { flag = "Overflow" }
        case .subtract:
            let raw = a &- b
            value = raw & mask
            if a < b { flag = "Underflow" }
        case .and: value = (a & b) & mask
        case .or: value = (a | b) & mask
        case .xor: value = (a ^ b) & mask
        case .shiftLeft: value = (a << (b % 64)) & mask
        case .shiftRight: value = (a >> (b % 64)) & mask
        case .notA: value = (~a) & mask
        case .negA: value = (0 &- a) & mask
        case .checksumOnes: value = (~(a &+ b)) & mask
        case .checksumTwos: value = ((~(a &+ b)) &+ 1) & mask
        }

        resultHex = formatHex(value, bits: selectedBitWidth.rawValue)
        resultDecimal = "\(value)"
        status = flag
        appendHistoryEntry(a: a, b: selectedOperation.isUnary ? nil : b)
    }

    private func appendHistoryEntry(a: UInt64, b: UInt64?) {
        let aHex = formatHex(a, bits: selectedBitWidth.rawValue)
        let bHex = b.map { formatHex($0, bits: selectedBitWidth.rawValue) } ?? ""
        let entry = HistoryEntry(id: UUID(), timestamp: Date(), bitWidth: selectedBitWidth.rawValue, operation: selectedOperation.rawValue, inputA: aHex, inputB: bHex, resultHex: resultHex, resultDecimal: resultDecimal, status: status)
        history.insert(entry, at: 0)
        if history.count > 100 { history.removeLast() }
        saveHistory()
    }

    private func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = decoded
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func applyWindowLevel() {
        let targetLevel: NSWindow.Level = alwaysOnTop ? .floating : .normal

        if let window = hostWindow {
            window.level = targetLevel
        }
        if let window = NSApp.keyWindow {
            window.level = targetLevel
        }
        if let window = NSApp.mainWindow {
            window.level = targetLevel
        }
    }

    private func setAlwaysOnTop(_ enabled: Bool) {
        alwaysOnTop = enabled
    }

    private func toggleAlwaysOnTop() {
        alwaysOnTop.toggle()
    }
}

// MARK: - Extensions
extension Color {
    static let darkGray = Color(white: 0.18)
    static let mediumGray = Color(white: 0.4)
    static let lightGray = Color(white: 0.6)
}

private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
    }
}

extension Notification.Name {
    static let hexFloatOnTopOn = Notification.Name("HexCalculator.FloatOnTop.On")
    static let hexFloatOnTopOff = Notification.Name("HexCalculator.FloatOnTop.Off")
    static let hexFloatOnTopToggle = Notification.Name("HexCalculator.FloatOnTop.Toggle")
}

#Preview {
    ContentView()
}
