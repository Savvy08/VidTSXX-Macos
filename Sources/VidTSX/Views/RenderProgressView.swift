import SwiftUI

public struct RenderProgressView: View {
    @ObservedObject var engine: RenderEngine
    let outputURL: URL?
    let onDismiss: () -> Void
    
    public init(engine: RenderEngine, outputURL: URL?, onDismiss: @escaping () -> Void) {
        self.engine = engine
        self.outputURL = outputURL
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(engine.state.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if engine.state == .completed || isFailed {
                    Button("Закрыть", action: onDismiss)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Button("Отмена", action: engine.cancel)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: engine.progress.percent, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.cyan)
                
                HStack {
                    Text("\(Int(engine.progress.percent * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    Text("\(engine.progress.currentFrame) / \(engine.progress.totalFrames) кадров")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            if engine.state == .completed, let url = outputURL {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Сохранено: \(url.lastPathComponent)")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Показать в Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.green.opacity(0.12))
                .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private var isFailed: Bool {
        if case .failed = engine.state { return true }
        return false
    }
}
