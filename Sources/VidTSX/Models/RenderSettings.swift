import Foundation

public enum ConcurrencyMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case eco = "Экономия"
    case balanced = "Баланс"
    case turbo = "Максимум"
    
    public var id: String { rawValue }
    
    public var subtitle: String {
        switch self {
        case .eco: return "Минимум нагрева, 2 потока"
        case .balanced: return "Оптимально, 4 потока"
        case .turbo: return "Полная мощность"
        }
    }
    
    public var threadCount: Int {
        switch self {
        case .eco: return 2
        case .balanced: return 4
        case .turbo: return ProcessInfo.processInfo.activeProcessorCount
        }
    }
}

public struct RenderSettings: Codable, Equatable, Sendable {
    public var concurrency: ConcurrencyMode = .balanced
    public var enableVideoToolbox: Bool = true
    public var backgroundPriority: Bool = true
    public var limitMemoryMB: Int = 1024
    
    public var exportDirectoryPath: String = {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        return desktop?.path ?? (NSHomeDirectory() + "/Desktop")
    }()
    
    public var exportDirectoryURL: URL {
        return URL(fileURLWithPath: exportDirectoryPath)
    }
    
    public init() {}
}
