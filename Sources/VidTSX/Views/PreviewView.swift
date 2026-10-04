import SwiftUI
import WebKit

public struct PreviewView: View {
    let fileURL: URL
    let config: CompositionConfig
    let componentName: String
    let code: String
    let onReset: () -> Void
    
    @Binding var webViewRef: WKWebView?
    @State private var currentFrame: Int = 0
    @State private var isPlaying: Bool = false
    
    public init(
        fileURL: URL,
        config: CompositionConfig,
        componentName: String,
        code: String,
        webViewRef: Binding<WKWebView?>,
        onReset: @escaping () -> Void
    ) {
        self.fileURL = fileURL
        self.config = config
        self.componentName = componentName
        self.code = code
        self._webViewRef = webViewRef
        self.onReset = onReset
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Компактная верхняя плашка информации
            HStack(spacing: 8) {
                Text(fileURL.lastPathComponent)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                badgeView(title: config.resolutionTitle, color: .cyan)
                badgeView(title: "\(config.fps) FPS", color: .green)
                badgeView(title: "\(String(format: "%.1f", config.durationInSeconds))с", color: .orange)
                
                Spacer()
                
                Button(action: onReset) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            
            // Парящий экран плеера
            ZStack {
                Color.black
                
                RemotionPlayerView(
                    code: code,
                    config: config,
                    currentFrame: $currentFrame,
                    isPlaying: $isPlaying,
                    webViewRef: $webViewRef
                )
            }
            .aspectRatio(CGFloat(config.width) / CGFloat(max(1, config.height)), contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 14)
            
            // Таймлайн управления
            HStack(spacing: 12) {
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Slider(value: Binding(
                    get: { Double(currentFrame) },
                    set: {
                        currentFrame = Int($0)
                        isPlaying = false
                    }
                ), in: 0...Double(max(1, config.totalFrames - 1)))
                .controlSize(.small)
                
                Text("\(currentFrame) / \(config.totalFrames)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
    }
    
    private func badgeView(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
