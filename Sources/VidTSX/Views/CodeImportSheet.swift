import SwiftUI
import AppKit

public struct CodeImportSheet: View {
    @Binding var isPresented: Bool
    var onImportCode: (String) -> Void
    
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var codeText: String = ""
    
    public init(isPresented: Binding<Bool>, onImportCode: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.onImportCode = onImportCode
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(loc.t("Импорт кода TSX", "Import TSX Code"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: pasteFromClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text(loc.t("Вставить из буфера", "Paste from Clipboard"))
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            TextEditor(text: $codeText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(minHeight: 260)
            
            HStack {
                Button(loc.t("Отмена", "Cancel")) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.white.opacity(0.6))
                
                Spacer()
                
                Button(action: performImport) {
                    Text(loc.t("Загрузить видео", "Load Video"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.regular)
                .disabled(codeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 580, height: 380)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
    }
    
    private func pasteFromClipboard() {
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            codeText = clipboardString
        }
    }
    
    private func performImport() {
        let trimmed = codeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onImportCode(trimmed)
        isPresented = false
    }
}
