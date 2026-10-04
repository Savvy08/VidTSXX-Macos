import SwiftUI

public struct SettingsView: View {
    @Binding var settings: RenderSettings
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var cacheClearedMessage: String? = nil
    
    public init(settings: Binding<RenderSettings>) {
        self._settings = settings
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.t("Язык интерфейса", "Interface Language"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Picker("", selection: $loc.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.title(for: loc.language)).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(loc.t("По умолчанию подстраивается под язык macOS.", "Defaults to your macOS system language."))
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(14)
                .background(Color(red: 0.11, green: 0.12, blue: 0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.t("Папка для сохранения", "Export Destination"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        Text(displayPath(settings.exportDirectoryPath))
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(6)
                        
                        Button(loc.t("Выбрать", "Browse"), action: chooseExportFolder)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    
                    Text(loc.t("Видео сохраняются сюда автоматически без лишних окон.", "Videos save here automatically without prompts."))
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(14)
                .background(Color(red: 0.11, green: 0.12, blue: 0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(loc.t("Режим нагрузки CPU", "CPU Load Mode"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Picker("", selection: $settings.concurrency) {
                        ForEach(ConcurrencyMode.allCases) { mode in
                            Text(concurrencyTitle(mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(concurrencySubtitle(settings.concurrency))
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    
                    Divider().background(Color.white.opacity(0.08))
                    
                    Toggle(isOn: $settings.enableVideoToolbox) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.t("Аппаратное ускорение", "Hardware Acceleration"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(loc.t("Кодирование на видеочипе без нагрузки на ядра", "Encode on media engine without CPU load"))
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Toggle(isOn: $settings.backgroundPriority) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.t("Фоновый режим", "Background Priority"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(loc.t("Система и браузер не тормозят при экспорте", "Keeps system and browsers fluid during render"))
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                    .toggleStyle(.switch)
                    
                    HStack {
                        Text(loc.t("Лимит памяти", "Memory Cap"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $settings.limitMemoryMB) {
                            Text(loc.t("1 ГБ", "1 GB")).tag(1024)
                            Text(loc.t("1.5 ГБ", "1.5 GB")).tag(1536)
                            Text(loc.t("2 ГБ", "2 GB")).tag(2048)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 90)
                    }
                }
                .padding(14)
                .background(Color(red: 0.11, green: 0.12, blue: 0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc.t("Кэш программы", "App Cache"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text(loc.t("Удаление временных файлов сборки и экспорта", "Delete temporary build and export files"))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Button(action: cleanCache) {
                        if let msg = cacheClearedMessage {
                            Text(msg).foregroundColor(.green)
                        } else {
                            Text(loc.t("Очистить кэш", "Clear Cache"))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(14)
                .background(Color(red: 0.11, green: 0.12, blue: 0.15))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .frame(maxWidth: 480)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
    
    private func concurrencyTitle(_ mode: ConcurrencyMode) -> String {
        switch mode {
        case .eco: return loc.t("Экономия", "Eco")
        case .balanced: return loc.t("Баланс", "Balanced")
        case .turbo: return loc.t("Максимум", "Maximum")
        }
    }
    
    private func concurrencySubtitle(_ mode: ConcurrencyMode) -> String {
        switch mode {
        case .eco: return loc.t("Минимум нагрева, 2 потока", "Minimum heat, 2 threads")
        case .balanced: return loc.t("Оптимально, 4 потока", "Optimal balance, 4 threads")
        case .turbo: return loc.t("Полная мощность", "Full power, all cores")
        }
    }
    
    private func chooseExportFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = loc.t("Выбрать", "Select")
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.exportDirectoryPath = url.path
        }
    }
    
    private func displayPath(_ fullPath: String) -> String {
        let home = NSHomeDirectory()
        if fullPath.hasPrefix(home) {
            return "~" + fullPath.dropFirst(home.count)
        }
        return fullPath
    }
    
    private func cleanCache() {
        let fm = FileManager.default
        let currentDir = URL(fileURLWithPath: fm.currentDirectoryPath)
        let buildDir = currentDir.appendingPathComponent(".build")
        let tmpDir = currentDir.appendingPathComponent("tmp")
        
        try? fm.removeItem(at: buildDir)
        try? fm.removeItem(at: tmpDir)
        
        withAnimation {
            cacheClearedMessage = loc.t("Очищено", "Cleared")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                cacheClearedMessage = nil
            }
        }
    }
}
