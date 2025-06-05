import SwiftUI
import AVFoundation
import Vision

class CameraPreviewView: NSView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let session = AVCaptureSession()
    private let handTrackingManager = HandTrackingManager()
    private var overlayLayer = CAShapeLayer()
    private var crestImage: NSImage? = nil
    private var ritualVM: RitualViewModel? = nil
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initializeCamera()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeCamera()
    }
    func setCrest(_ image: NSImage?) {
        self.crestImage = image
    }
    func setRitualVM(_ vm: RitualViewModel) {
        self.ritualVM = vm
    }
    private func initializeCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing"))
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer = CALayer()
        layer?.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        overlayLayer.frame = bounds
        overlayLayer.strokeColor = NSColor.green.cgColor
        overlayLayer.fillColor = NSColor.green.withAlphaComponent(0.3).cgColor
        layer?.addSublayer(overlayLayer)
        session.commitConfiguration()
        session.startRunning()
    }
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
        overlayLayer.frame = bounds
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handTrackingManager.processSampleBuffer(sampleBuffer)
        DispatchQueue.main.async {
            self.overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            guard let hand = self.handTrackingManager.handPose else { return }
            // Gesture detection: open palm vs fist
            let tip = try? hand.recognizedPoint(.indexTip)
            let pip = try? hand.recognizedPoint(.indexPIP)
            if let tip = tip, let pip = pip, tip.confidence > 0.5, pip.confidence > 0.5 {
                let cgPoint = CGPoint(x: tip.location.x * self.bounds.width, y: (1 - tip.location.y) * self.bounds.height)
                // Overlay crest at fingertip
                if let crest = self.crestImage {
                    let crestLayer = CALayer()
                    crestLayer.contents = crest.cgImage(forProposedRect: nil, context: nil, hints: nil)
                    crestLayer.frame = CGRect(x: cgPoint.x - 32, y: cgPoint.y - 32, width: 64, height: 64)
                    self.overlayLayer.addSublayer(crestLayer)
                } else {
                    let circle = NSBezierPath(ovalIn: CGRect(x: cgPoint.x - 16, y: cgPoint.y - 16, width: 32, height: 32))
                    let shape = CAShapeLayer()
                    shape.path = circle.cgPath
                    shape.fillColor = NSColor.green.withAlphaComponent(0.5).cgColor
                    self.overlayLayer.addSublayer(shape)
                }
                // Gesture logic
                let gesture: String
                if tip.location.y < pip.location.y {
                    gesture = "open_palm"
                } else {
                    gesture = "fist"
                }
                // Send gesture to Mac API and log
                self.ritualVM?.sendGestureCommand(gesture)
            }
        }
    }
}

struct CameraView: NSViewRepresentable {
    @EnvironmentObject var ritualVM: RitualViewModel
    func makeNSView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView(frame: .zero)
        view.setCrest(ritualVM.crest)
        view.setRitualVM(ritualVM)
        return view
    }
    func updateNSView(_ nsView: CameraPreviewView, context: Context) {
        nsView.setCrest(ritualVM.crest)
    }
} 