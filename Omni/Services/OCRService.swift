import Foundation
import Vision
import AppKit // For NSImage

class OCRService {
    
    /// Extracts all text from an image at a given URL.
    /// - Parameter url: The file URL of the image (jpg, png, etc.).
    /// - Returns: A single string of all recognized text, or nil if it fails.
    func extractText(from imageURL: URL) async -> String? {
        // 1. Load the image from the file URL
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            print("OCR Error: Could not load NSImage from URL: \(imageURL)")
            return nil
        }
        
        // 2. Convert to a CGImage, which Vision framework requires
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("OCR Error: Could not convert NSImage to CGImage.")
            return nil
        }
        
        // 3. Wrap the request in an async function with explicit type
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            
            // 4. Define the completion handler
            let completionHandler: VNRequestCompletionHandler = { (request, error) in
                if let error = error {
                    print("OCR Vision Error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 5. Extract and combine all the recognized text
                let recognizedStrings: [String] = observations.compactMap { observation -> String? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    if topCandidate.confidence > 0.4 {
                        return topCandidate.string
                    } else {
                        return nil
                    }
                }
                
                let finalString = recognizedStrings.joined(separator: "\n\n")
                
                if finalString.isEmpty {
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: finalString)
                }
            }
            
            // 6. Create the request
            let request = VNRecognizeTextRequest(completionHandler: completionHandler)
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false

            // 7. Perform the request
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print("OCR Request Handler Error: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
        }
    }
}
