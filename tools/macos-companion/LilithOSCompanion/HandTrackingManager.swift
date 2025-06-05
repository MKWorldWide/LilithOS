import Foundation
import Vision
import AVFoundation

class HandTrackingManager: NSObject, ObservableObject {
    @Published var handPose: VNHumanHandPoseObservation?
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let sequenceHandler = VNSequenceRequestHandler()
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let result = handPoseRequest.results?.first {
                DispatchQueue.main.async {
                    self.handPose = result
                }
            }
        } catch {
            print("Hand pose detection failed: \(error)")
        }
    }
} 