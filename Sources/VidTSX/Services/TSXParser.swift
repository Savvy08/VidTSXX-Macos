import Foundation

public final class TSXParser {
    public static let shared = TSXParser()
    
    public func parse(fileURL: URL) throws -> (config: CompositionConfig, componentName: String, code: String) {
        let code = try String(contentsOf: fileURL, encoding: .utf8)
        return parse(code: code, defaultId: fileURL.deletingPathExtension().lastPathComponent)
    }
    
    public func parse(code: String, defaultId: String = "Composition") -> (config: CompositionConfig, componentName: String, code: String) {
        var id = defaultId
        var durationInSeconds = 5.0
        var fps = 60
        var width = 1920
        var height = 1080
        
        // 1. Поиск id
        if let match = matchValue(in: code, pattern: #"\bid\s*:\s*['"]([^'"]+)['"]"#) {
            id = match
        }
        
        // 2. Поиск durationInSeconds
        if let match = matchValue(in: code, pattern: #"\bdurationInSeconds\s*:\s*([0-9]+(?:\.[0-9]+)?)"#),
           let val = Double(match) {
            durationInSeconds = val
        }
        
        // 3. Поиск fps
        if let match = matchValue(in: code, pattern: #"\bfps\s*:\s*([0-9]+)"#),
           let val = Int(match) {
            fps = val
        }
        
        // 4. Поиск width
        if let match = matchValue(in: code, pattern: #"\bwidth\s*:\s*([0-9]+)"#),
           let val = Int(match) {
            width = val
        }
        
        // 5. Поиск height
        if let match = matchValue(in: code, pattern: #"\bheight\s*:\s*([0-9]+)"#),
           let val = Int(match) {
            height = val
        }
        
        // 6. Поиск имени экспортируемого компонента
        var componentName = id
        if let match = matchValue(in: code, pattern: #"export\s+default\s+([A-Za-z0-9_]+)"#) {
            componentName = match
        } else if let match = matchValue(in: code, pattern: #"const\s+([A-Za-z0-9_]+)\s*:\s*React\.FC"#) {
            componentName = match
        }
        
        let config = CompositionConfig(
            id: id,
            durationInSeconds: durationInSeconds,
            fps: fps,
            width: width,
            height: height
        )
        
        return (config, componentName, code)
    }
    
    private func matchValue(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}
