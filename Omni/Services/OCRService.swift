import Foundation
import Vision
import AppKit // For NSImage

// 1. Define specific errors your service can throw
enum OCRError: Error {
    case imageLoadFailed
    case imageConversionFailed
    case visionRequestFailed(Error)
    case noTextFound
}

class OCRService {
    
    /// Extracts all text from an image at a given URL.
    /// - Parameter url: The file URL of the image (jpg, png, etc.).
    /// - Returns: A single string of all recognized text.
    /// - Throws: An OCRError if the process fails at any step.
    func extractText(from imageURL: URL) async throws -> String {
        
        // 1. Load the image from the file URL
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            print("OCR Error: Could not load NSImage from URL: \(imageURL)")
            throw OCRError.imageLoadFailed
        }
        
        // 2. Convert to a CGImage, which Vision framework requires
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("OCR Error: Could not convert NSImage to CGImage.")
            throw OCRError.imageConversionFailed
        }
        
        // 3. Wrap the request in a throwing continuation
        return try await withCheckedThrowingContinuation { continuation in
            
            // 4. Define the completion handler
            let completionHandler: VNRequestCompletionHandler = { (request, error) in
                if let error = error {
                    print("OCR Vision Error: \(error.localizedDescription)")
                    continuation.resume(throwing: OCRError.visionRequestFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // 5. Extract and combine all the recognized text
                let recognizedStrings: [String] = observations.compactMap { observation -> String? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    // --- ACCURACY FIX 2 ---
                    // Increased confidence threshold
                    if topCandidate.confidence > 0.7 {
                        return topCandidate.string
                    } else {
                        return nil
                    }
                }
                
                let finalString = recognizedStrings.joined(separator: "\n\n")
                
                if finalString.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: finalString)
                }
            }
            
            // 6. Create the request
            let request = VNRecognizeTextRequest(completionHandler: completionHandler)
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"] // Keep this limited if you only expect English
            
            // --- ACCURACY FIX 1 ---
            // Enable language correction for much better results
            request.usesLanguageCorrection = true

            // 7. Perform the request
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print("OCR Request Handler Error: \(error.localizedDescription)")
                continuation.resume(throwing: OCRError.visionRequestFailed(error))
            }
        }
    }
}
