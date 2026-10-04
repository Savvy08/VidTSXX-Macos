import SwiftUI
import UniformTypeIdentifiers

public struct DropZoneView: View {
    @Binding var selectedFileURL: URL?
    var onFileSelected: (URL) -> Void
    var onOpenCodeImport: () -> Void
    
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var isTargeted: Bool = false
    
    public init(
        selectedFileURL: Binding<URL?>,
        onFileSelected: @escaping (URL) -> Void,
        onOpenCodeImport: @escaping () -> Void
    ) {
        self._selectedFileURL = selectedFileURL
        self.onFileSelected = onFileSelected
        self.onOpenCodeImport = onOpenCodeImport
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                    .frame(width: 58, height: 58)
                
                Image(systemName: isTargeted ? "arrow.down.doc.fill" : "film")
                    .font(.system(size: 24))
                    .foregroundColor(isTargeted ? .cyan : Color.white.opacity(0.6))
            }
            
            VStack(spacing: 4) {
                Text(selectedFileURL != nil ? selectedFileURL!.lastPathComponent : loc.t("Перетащите файл .tsx сюда", "Drop .tsx file here"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(loc.t("Поддерживаются React Remotion композиции", "Supports React Remotion compositions"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            
            HStack(spacing: 10) {
                Button(action: selectFileManually) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(loc.t("Выбрать файл", "Open File"))
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Button(action: onOpenCodeImport) {
                    HStack(spacing: 4) {
                        Image(systemName: "curlybraces")
                        Text(loc.t("Вставить код", "Paste Code"))
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isTargeted ? Color.cyan : Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        )
        .cornerRadius(10)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url, url.pathExtension.lowercased() == "tsx" else { return }
                DispatchQueue.main.async {
                    self.selectedFileURL = url
                    self.onFileSelected(url)
                }
            }
            return true
        }
    }
    
    private func selectFileManually() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "tsx") ?? .item]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = loc.t("Выбрать", "Select")
        
        if panel.runModal() == .OK, let url = panel.url {
            self.selectedFileURL = url
            self.onFileSelected(url)
        }
    }
}
