import Foundation
import AVFoundation
import CoreGraphics
import CoreVideo

public final class VideoToolboxEncoder {
    private var assetWriter: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private let width: Int
    private let height: Int
    private let fps: Int
    private let outputURL: URL
    
    public init(outputURL: URL, width: Int, height: Int, fps: Int) {
        self.outputURL = outputURL
        self.width = width
        self.height = height
        self.fps = fps
    }
    
    public func start() throws {
        // Удалить старый файл если существует
        try? FileManager.default.removeItem(at: outputURL)
        
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: width * height * 8, // Высокое качество
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        if writer.canAdd(input) {
            writer.add(input)
        }
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        self.assetWriter = writer
        self.writerInput = input
        self.pixelBufferAdaptor = adaptor
    }
    
    public func appendFrame(cgImage: CGImage, frameIndex: Int) -> Bool {
        guard let input = writerInput, let adaptor = pixelBufferAdaptor else { return false }
        
        while !input.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.005)
        }
        
        guard let pixelBuffer = newPixelBufferFromCGImage(cgImage: cgImage) else { return false }
        let presentationTime = CMTime(value: Int64(frameIndex), timescale: Int32(fps))
        return adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
    
    public func finish() async -> Bool {
        guard let writer = assetWriter, let input = writerInput else { return false }
        input.markAsFinished()
        
        return await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume(returning: writer.status == .completed)
            }
        }
    }
    
    private func newPixelBufferFromCGImage(cgImage: CGImage) -> CVPixelBuffer? {
        guard let pool = pixelBufferAdaptor?.pixelBufferPool else { return nil }
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
