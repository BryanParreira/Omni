import Foundation
import AppKit
import Vision
import ScreenCaptureKit // For screen capture
import CoreVideo       // For pixel format
import CoreImage       // For converting to CGImage

/**
 This service is responsible for capturing the text context from the
 user's currently active window.
 
 It uses a two-pronged approach:
 1. Accessibility API: Tries to get selected or focused text. This is fast and precise.
 2. OCR Fallback (ScreenCaptureKit): If Accessibility fails, it takes a screenshot of the active
    window and uses Optical Character Recognition.
 */
class ContextCaptureService {
    
    static let shared = ContextCaptureService()
    
    // Create a CIContext to re-use for image conversion
    private let ciContext = CIContext()
    
    private init() {}
    
    /**
     Captures text from the user's currently active window.
     
     - Parameter completion: A closure called with an optional String
       containing the captured text. Called on the main thread.
     */
    public func captureCurrentContext(completion: @escaping (String?) -> Void) {
        
        // 1. Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let pid = frontApp.processIdentifier
        
        // 2. Try getting text via Accessibility
        let appElement = AXUIElementCreateApplication(pid)
        var focusedElement: AnyObject?
        
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
           let element = focusedElement as! AXUIElement? {
            
            var selectedTextValue: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedTextValue) == .success,
               let selectedText = selectedTextValue as? String, !selectedText.isEmpty {
                
                print("ContextCapture: Success (Accessibility Selected Text)")
                DispatchQueue.main.async { completion(selectedText) }
                return
            }
            
            var allTextValue: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &allTextValue) == .success,
               let allText = allTextValue as? String, !allText.isEmpty {
                
                print("ContextCapture: Success (Accessibility Focused Element)")
                DispatchQueue.main.async { completion(allText) }
                return
            }
        }
        
        // 3. Fallback to OCR if Accessibility fails
        print("ContextCapture: Accessibility failed. Falling back to OCR.")
        
        // We need to run the new async OCR function
        Task {
            let ocrText = await captureScreenOCR(pid: pid)
            DispatchQueue.main.async {
                completion(ocrText)
            }
        }
    }
    
    /**
     Private fallback function to capture the active window via ScreenCaptureKit and OCR.
     */
    private func captureScreenOCR(pid: pid_t) async -> String? {
        do {
            // Get the list of shareable windows
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // Find the window that matches our frontmost app's PID
            guard let frontWindow = content.windows.first(where: {
                $0.owningApplication?.processID == pid && $0.isOnScreen
            }) else {
                print("ContextCapture: OCR failed. Could not find shareable window for PID \(pid).")
                return nil
            }
            
            // This filter selects only our target window
            let filter = SCContentFilter(desktopIndependentWindow: frontWindow)
            
            // Configuration for a single-frame capture
            let config = SCStreamConfiguration()
            
            config.width = Int(frontWindow.frame.width)
            config.height = Int(frontWindow.frame.height)
            config.captureResolution = .best
            config.pixelFormat = kCVPixelFormatType_32BGRA // 'BGRA'
            
            // --- THIS IS THE FIX ---
            // The ScreenCaptureActor initializer is isolated to the @MainActor,
            // so we must 'await' its creation.
            let captureActor = await ScreenCaptureActor(config: config, filter: filter, ciContext: self.ciContext)
            // --- END OF FIX ---
            
            // Get the image from the actor
            guard let image = await captureActor.captureFrame() else {
                print("ContextCapture: OCR failed. Actor did not return an image.")
                return nil
            }
            
            // Run Vision request
            return await performVisionRequest(on: image)
            
        } catch {
            print("ContextCapture: OCR failed with error: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    /**
     Performs the Vision OCR request on a given CGImage using modern async/await.
     */
    private func performVisionRequest(on image: CGImage) async -> String? {
        
        let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
        
        // We initialize the request *without* a completion handler
        let request = VNRecognizeTextRequest()
        
        do {
            // Use the modern 'async throws' perform method
            try await requestHandler.perform([request])
            
            // If it succeeds, the results will be on the request object
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("ContextCapture: OCR request failed. No observations.")
                return nil
            }
            
            let recognizedText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            print("ContextCapture: Success (OCR)")
            return recognizedText.isEmpty ? nil : recognizedText
            
        } catch {
            print("ContextCapture: OCR perform failed: \(error)")
            return nil
        }
    }
}

/**
 This helper actor manages the SCStream to capture a single frame.
 */
@MainActor
private class ScreenCaptureActor: NSObject, SCStreamOutput {
    
    private var stream: SCStream?
    private let config: SCStreamConfiguration
    private let filter: SCContentFilter
    private let ciContext: CIContext // Pass in the context
    
    // This Continuation is how we send the result back asynchronously
    private var continuation: CheckedContinuation<CGImage?, Never>?

    init(config: SCStreamConfiguration, filter: SCContentFilter, ciContext: CIContext) {
        self.config = config
        self.filter = filter
        self.ciContext = ciContext
        super.init()
        
        self.stream = SCStream(filter: filter, configuration: config, delegate: nil)
    }

    public func captureFrame() async -> CGImage? {
        guard let stream = stream else { return nil }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            
            do {
                // Add the stream output handler (self)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                stream.startCapture()
            } catch {
                print("Actor Error: Failed to add stream output: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }

    // This delegate method is called when a frame is available
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let continuation = continuation else { return }

        // Stop capturing immediately, we only want one frame
        stream.stopCapture()

        guard CMSampleBufferIsValid(sampleBuffer),
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            print("Actor Error: Failed to get image buffer from sample.")
            continuation.resume(returning: nil)
            self.continuation = nil
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Actor Error: Failed to create CGImage from CIImage.")
            continuation.resume(returning: nil)
            self.continuation = nil
            return
        }

        // Success! Send the image back
        continuation.resume(returning: cgImage)
        self.continuation = nil
    }
}
