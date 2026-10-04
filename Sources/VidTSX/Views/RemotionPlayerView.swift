import SwiftUI
import WebKit

public struct RemotionPlayerView: NSViewRepresentable {
    let code: String
    let config: CompositionConfig
    @Binding var currentFrame: Int
    @Binding var isPlaying: Bool
    @Binding var webViewRef: WKWebView?
    
    public init(
        code: String,
        config: CompositionConfig,
        currentFrame: Binding<Int>,
        isPlaying: Binding<Bool>,
        webViewRef: Binding<WKWebView?>
    ) {
        self.code = code
        self.config = config
        self._currentFrame = currentFrame
        self._isPlaying = isPlaying
        self._webViewRef = webViewRef
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: "frameChanged")
        configuration.userContentController = userController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        
        context.coordinator.webView = webView
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        
        loadHTML(into: webView)
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: Context) {
        // Управление воспроизведением внутри WebKit
        if context.coordinator.lastPlayingState != isPlaying {
            context.coordinator.lastPlayingState = isPlaying
            if isPlaying {
                nsView.evaluateJavaScript("if (window.play) { window.play(); }")
            } else {
                nsView.evaluateJavaScript("if (window.pause) { window.pause(); }")
            }
        }
        
        // Ручная перемотка ползунком
        if !isPlaying && context.coordinator.lastReportedFrame != currentFrame {
            context.coordinator.lastReportedFrame = currentFrame
            nsView.evaluateJavaScript("if (window.seekFrame) { window.seekFrame(\(currentFrame)); }")
        }
    }
    
    private func loadHTML(into webView: WKWebView) {
        var htmlURL: URL?
        if let bundleURL = Bundle.main.url(forResource: "player", withExtension: "html", subdirectory: "web") {
            htmlURL = bundleURL
        } else {
            let localURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Resources/web/player.html")
            if FileManager.default.fileExists(atPath: localURL.path) {
                htmlURL = localURL
            }
        }
        
        if let url = htmlURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    
    public final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: RemotionPlayerView
        weak var webView: WKWebView?
        var lastReportedFrame: Int = -1
        var lastPlayingState: Bool = false
        
        init(_ parent: RemotionPlayerView) {
            self.parent = parent
        }
        
        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "frameChanged", let frame = message.body as? Int {
                DispatchQueue.main.async {
                    self.lastReportedFrame = frame
                    self.parent.currentFrame = frame
                }
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let escapedCode = parent.code
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
            
            let js = """
            const cfg = {
                width: \(parent.config.width),
                height: \(parent.config.height),
                fps: \(parent.config.fps),
                durationInFrames: \(parent.config.totalFrames)
            };
            window.loadTSX(`\(escapedCode)`, cfg);
            window.seekFrame(\(parent.currentFrame));
            """
            
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("[VidTSX Player Error]: \(error.localizedDescription)")
                }
            }
        }
    }
}
