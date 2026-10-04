import SwiftUI
import WebKit

public enum AppTab: String, CaseIterable, Identifiable {
    case renderer = "renderer"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public func title(loc: LocalizationManager) -> String {
        switch self {
        case .renderer: return loc.t("Рендер TSX", "TSX Renderer")
        case .settings: return loc.t("Настройки", "Settings")
        }
    }
    
    public var icon: String {
        switch self {
        case .renderer: return "film"
        case .settings: return "gearshape"
        }
    }
}

public struct ContentView: View {
    @State private var currentTab: AppTab = .renderer
    @State private var selectedFileURL: URL? = nil
    @State private var config: CompositionConfig? = nil
    @State private var componentName: String = ""
    @State private var tsxCode: String = ""
    @State private var isShowingCodeImport: Bool = false
    
    @StateObject private var renderEngine = RenderEngine.shared
    @StateObject private var loc = LocalizationManager.shared
    @State private var settings = RenderSettings()
    @State private var targetOutputURL: URL? = nil
    @State private var webViewRef: WKWebView? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Верхняя парящая панель
            headerView
            
            Divider().background(Color.white.opacity(0.08))
            
            // Основное содержимое
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
                
                switch currentTab {
                case .renderer:
                    rendererTabView
                case .settings:
                    SettingsView(settings: $settings)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
        .sheet(isPresented: $isShowingCodeImport) {
            CodeImportSheet(isPresented: $isShowingCodeImport) { rawCode in
                handlePastedCode(rawCode)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                
                Text("VidTSX")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Picker("", selection: $currentTab) {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.title(loc: loc), systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.09, green: 0.10, blue: 0.12))
    }
    
    private var rendererTabView: some View {
        VStack(spacing: 12) {
            if let fileURL = selectedFileURL, let cfg = config {
                PreviewView(
                    fileURL: fileURL,
                    config: cfg,
                    componentName: componentName,
                    code: tsxCode,
                    webViewRef: $webViewRef,
                    onReset: resetFile
                )
                
                // Нижняя панель действий
                bottomActionBar(cfg: cfg)
            } else {
                DropZoneView(
                    selectedFileURL: $selectedFileURL,
                    onFileSelected: handleFileSelection,
                    onOpenCodeImport: { isShowingCodeImport = true }
                )
                .padding(16)
            }
            
            // Прогресс рендера
            if renderEngine.state != .idle {
                RenderProgressView(
                    engine: renderEngine,
                    outputURL: targetOutputURL,
                    onDismiss: {
                        renderEngine.state = .idle
                    }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func bottomActionBar(cfg: CompositionConfig) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(loc.t("Экспорт: \(cfg.id).mp4", "Export: \(cfg.id).mp4"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                Text(loc.t("Папка: \(displayPath(settings.exportDirectoryPath))", "Folder: \(displayPath(settings.exportDirectoryPath))"))
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: { isShowingCodeImport = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "curlybraces")
                    Text(loc.t("Код", "Code"))
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            
            Button(action: {
                startDirectRender(cfg: cfg)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(loc.t("Конвертировать в MP4", "Convert to MP4"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .controlSize(.regular)
            .disabled(renderEngine.state == .rendering || webViewRef == nil)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
    
    private func displayPath(_ fullPath: String) -> String {
        let home = NSHomeDirectory()
        if fullPath.hasPrefix(home) {
            return "~" + fullPath.dropFirst(home.count)
        }
        return fullPath
    }
    
    private func handleFileSelection(_ url: URL) {
        do {
            let result = try TSXParser.shared.parse(fileURL: url)
            self.config = result.config
            self.componentName = result.componentName
            self.tsxCode = result.code
            self.selectedFileURL = url
        } catch {
            print("Ошибка парсинга TSX: \(error)")
        }
    }
    
    private func handlePastedCode(_ rawCode: String) {
        let result = TSXParser.shared.parse(code: rawCode, defaultId: "ImportedComposition")
        self.config = result.config
        self.componentName = result.componentName
        self.tsxCode = result.code
        
        // Создание виртуального URL для отображения имени
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(result.config.id).tsx")
        try? rawCode.write(to: tempURL, atomically: true, encoding: .utf8)
        self.selectedFileURL = tempURL
    }
    
    private func resetFile() {
        self.selectedFileURL = nil
        self.config = nil
        self.componentName = ""
        self.tsxCode = ""
        self.webViewRef = nil
    }
    
    private func startDirectRender(cfg: CompositionConfig) {
        guard let webView = webViewRef else { return }
        
        let destinationDir = settings.exportDirectoryURL
        let outURL = destinationDir.appendingPathComponent("\(cfg.id).mp4")
        self.targetOutputURL = outURL
        
        Task {
            await renderEngine.renderWithWebKit(
                webView: webView,
                config: cfg,
                settings: settings,
                outputURL: outURL
            )
        }
    }
}
