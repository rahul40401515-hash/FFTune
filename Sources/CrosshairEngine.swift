import SwiftUI
import AVKit
import AVFoundation
import CoreGraphics
import UIKit

final class CrosshairEngine: NSObject, ObservableObject, AVPictureInPictureSampleBufferPlaybackDelegate {
    @Published var isActive = false
    @Published var tint: Color = .green
    @Published var side: Double = 140
    @Published var thickness: Double = 3
    @Published var gap: Double = 10

    let layer = AVSampleBufferDisplayLayer()
    private var pip: AVPictureInPictureController?
    private var timer: Timer?
    private var silence: AVAudioPlayer?

    func start() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        silence = try? AVAudioPlayer(data: Self.silence())
        silence?.numberOfLoops = -1
        silence?.volume = 0.001
        silence?.play()

        let source = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: layer, playbackDelegate: self)
        pip = AVPictureInPictureController(contentSource: source)
        render()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            self?.render()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.pip?.startPictureInPicture()
            self?.isActive = true
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        pip?.stopPictureInPicture()
        silence?.stop()
        isActive = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func render() {
        let s = Int(side)
        guard let buf = Self.buffer(s, s) else { return }
        CVPixelBufferLockBaseAddress(buf, [])
        defer { CVPixelBufferUnlockBaseAddress(buf, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf),
                                  width: s, height: s, bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(buf),
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                      | CGBitmapInfo.byteOrder32Little.rawValue) else { return }

        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

        let c = CGFloat(s) / 2
        let g = CGFloat(gap)
        let e = CGFloat(8)
        ctx.setStrokeColor(UIColor(tint).cgColor)
        ctx.setLineWidth(CGFloat(thickness))
        ctx.move(to: CGPoint(x: c, y: c - g)); ctx.addLine(to: CGPoint(x: c, y: e))
        ctx.move(to: CGPoint(x: c, y: c + g)); ctx.addLine(to: CGPoint(x: c, y: CGFloat(s) - e))
        ctx.move(to: CGPoint(x: c - g, y: c)); ctx.addLine(to: CGPoint(x: e, y: c))
        ctx.move(to: CGPoint(x: c + g, y: c)); ctx.addLine(to: CGPoint(x: CGFloat(s) - e, y: c))
        ctx.strokePath()
        ctx.setFillColor(UIColor(tint).cgColor)
        ctx.fillEllipse(in: CGRect(x: c - 2, y: c - 2, width: 4, height: 4))

        guard let sample = Self.sample(buf) else { return }
        if layer.status == .failed { layer.flush() }
        layer.enqueue(sample)
    }

    private static func buffer(_ w: Int, _ h: Int) -> CVPixelBuffer? {
        var buf: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA,
                            attrs as CFDictionary, &buf)
        return buf
    }

    private static func sample(_ buf: CVPixelBuffer) -> CMSampleBuffer? {
        var fmt: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: buf,
                                                     formatDescriptionOut: &fmt)
        guard let fmt else { return nil }
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 15),
                                        presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                        decodeTimeStamp: .invalid)
        var out: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: buf, formatDescription: fmt,
                                                 sampleTiming: &timing, sampleBufferOut: &out)
        return out
    }

    private static func silence() -> Data {
        let rate: UInt32 = 8000
        let bytes = rate * 2
        var d = Data()
        func put<T>(_ v: T) { withUnsafeBytes(of: v) { d.append(contentsOf: $0) } }
        d.append("RIFF".data(using: .ascii)!); put(UInt32(36 + bytes).littleEndian)
        d.append("WAVEfmt ".data(using: .ascii)!); put(UInt32(16).littleEndian)
        put(UInt16(1).littleEndian); put(UInt16(1).littleEndian)
        put(rate.littleEndian); put((rate * 2).littleEndian)
        put(UInt16(2).littleEndian); put(UInt16(16).littleEndian)
        d.append("data".data(using: .ascii)!); put(UInt32(bytes).littleEndian)
        d.append(Data(count: Int(bytes)))
        return d
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ c: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: CMTime(value: 3600, timescale: 1))
    }
    func pictureInPictureControllerIsPlaybackPaused(_ c: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(_ c: AVPictureInPictureController, didTransitionToRenderSize s: CMVideoDimensions) {}
    func pictureInPictureController(_ c: AVPictureInPictureController, skipByInterval i: CMTime, completion: @escaping () -> Void) { completion() }
    func pictureInPictureController(_ c: AVPictureInPictureController, setPlaying playing: Bool) {}
}

final class LayerView: UIView {
    var hosted: AVSampleBufferDisplayLayer?
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        hosted?.frame = bounds
        CATransaction.commit()
    }
}

struct LayerHost: UIViewRepresentable {
    let layer: AVSampleBufferDisplayLayer
    func makeUIView(context: Context) -> LayerView {
        let v = LayerView()
        v.hosted = layer
        v.layer.addSublayer(layer)
        return v
    }
    func updateUIView(_ uiView: LayerView, context: Context) {}
}
