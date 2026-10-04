import Foundation

public struct CompositionConfig: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var durationInSeconds: Double
    public var fps: Int
    public var width: Int
    public var height: Int
    
    public var totalFrames: Int {
        return max(1, Int(durationInSeconds * Double(fps)))
    }
    
    public var resolutionTitle: String {
        return "\(width) × \(height)"
    }
    
    public var aspectRatio: String {
        let gcdValue = gcd(width, height)
        return "\(width / gcdValue):\(height / gcdValue)"
    }
    
    public init(
        id: String = "Untitled",
        durationInSeconds: Double = 5.0,
        fps: Int = 60,
        width: Int = 1920,
        height: Int = 1080
    ) {
        self.id = id
        self.durationInSeconds = durationInSeconds
        self.fps = fps
        self.width = width
        self.height = height
    }
    
    private func gcd(_ a: Int, _ b: Int) -> Int {
        var x = a
        var y = b
        while y != 0 {
            let temp = y
            y = x % y
            x = temp
        }
        return x == 0 ? 1 : abs(x)
    }
}
