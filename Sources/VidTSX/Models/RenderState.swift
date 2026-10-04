import Foundation

public enum RenderStatus: Equatable {
    case idle
    case parsing
    case ready
    case rendering
    case completed
    case failed(String)
    
    public var title: String {
        switch self {
        case .idle: return "Ожидание файла"
        case .parsing: return "Анализ TSX..."
        case .ready: return "Готов к рендеру"
        case .rendering: return "Идет экспорт..."
        case .completed: return "Рендер завершен"
        case .failed(let err): return "Ошибка: \(err)"
        }
    }
}

public struct RenderProgress: Equatable {
    public var currentFrame: Int = 0
    public var totalFrames: Int = 0
    public var fpsRate: Double = 0.0
    public var percent: Double = 0.0
    public var etaSeconds: Int = 0
    
    public init() {}
}
