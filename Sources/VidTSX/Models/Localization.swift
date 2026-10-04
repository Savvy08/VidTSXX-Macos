import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case system = "system"
    case russian = "ru"
    case english = "en"
    
    public var id: String { rawValue }
    
    public func title(for current: AppLanguage) -> String {
        switch self {
        case .system:
            return current.isRussian ? "Системный (авто)" : "System (Auto)"
        case .russian:
            return "Русский"
        case .english:
            return "English"
        }
    }
    
    public var isRussian: Bool {
        switch self {
        case .russian: return true
        case .english: return false
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("ru")
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "vidtsx_lang")
        }
    }
    
    public init() {
        let saved = UserDefaults.standard.string(forKey: "vidtsx_lang") ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: saved) ?? .system
    }
    
    public func t(_ ru: String, _ en: String) -> String {
        return language.isRussian ? ru : en
    }
}
