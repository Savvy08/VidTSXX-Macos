import Foundation
import WebKit
import CoreGraphics
import AppKit

public final class RenderEngine: ObservableObject {
    public static let shared = RenderEngine()
    
    @Published public var state: RenderStatus = .idle
    @Published public var progress: RenderProgress = RenderProgress()
    @Published public var logs: [String] = []
    
    private var isCancelled = false
    
    public init() {}
    
    @MainActor
    public func renderWithWebKit(
        webView: WKWebView,
        config: CompositionConfig,
        settings: RenderSettings,
        outputURL: URL
    ) async {
        await MainActor.run {
            self.state = .rendering
            self.isCancelled = false
            self.progress = RenderProgress()
            self.progress.totalFrames = config.totalFrames
            self.logs = []
            self.appendLog("Старт аппаратного рендера: \(outputURL.lastPathComponent)")
            self.appendLog("Разрешение: \(config.width)x\(config.height) @ \(config.fps) FPS")
        }
        
        let encoder = VideoToolboxEncoder(
            outputURL: outputURL,
            width: config.width,
            height: config.height,
            fps: config.fps
        )
        
        do {
            try encoder.start()
        } catch {
            await MainActor.run {
                self.state = .failed("Не удалось инициализировать кодировщик: \(error.localizedDescription)")
            }
            return
        }
        
        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.snapshotWidth = NSNumber(value: config.width)
        
        let total = config.totalFrames
        let startTime = Date()
        
        for frame in 0..<total {
            if isCancelled {
                await MainActor.run {
                    self.state = .idle
                    self.appendLog("Рендер отменен пользователем")
                }
                return
            }
            
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("window.seekFrame(\(frame));") { _, _ in
                        continuation.resume()
                    }
                }
            }
            
            try? await Task.sleep(nanoseconds: 12_000_000)
            
            let nsImage: NSImage? = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    webView.takeSnapshot(with: snapshotConfig) { img, err in
                        continuation.resume(returning: img)
                    }
                }
            }
            
            guard let image = nsImage,
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                continue
            }
            
            _ = encoder.appendFrame(cgImage: cgImage, frameIndex: frame)
            
            if frame % 5 == 0 || frame == total - 1 {
                let current = frame + 1
                let elapsed = Date().timeIntervalSince(startTime)
                let currentFps = Double(current) / max(0.001, elapsed)
                let pct = Double(current) / Double(total)
                
                await MainActor.run {
                    self.progress.currentFrame = current
                    self.progress.percent = pct
                    self.progress.fpsRate = currentFps
                }
            }
        }
        
        let success = await encoder.finish()
        
        await MainActor.run {
            if success && FileManager.default.fileExists(atPath: outputURL.path) {
                self.progress.percent = 1.0
                self.progress.currentFrame = total
                self.state = .completed
                self.appendLog("Готово: файл сохранен в \(outputURL.path)")
            } else {
                self.state = .failed("Ошибка завершения записи видео")
                self.appendLog("Ошибка финализации видеофайла")
            }
        }
    }
    
    public func cancel() {
        isCancelled = true
        DispatchQueue.main.async {
            self.state = .idle
            self.appendLog("Отмена рендера...")
        }
    }
    
    private func appendLog(_ message: String) {
        logs.append(message)
    }
}
