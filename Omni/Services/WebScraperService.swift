import Foundation
import SwiftSoup

class WebScraperService {
    
    /// Fetches a URL, parses the HTML, and returns the clean, visible text.
    func fetchAndCleanText(from url: URL) async -> String? {
        do {
            // 1. Fetch the web page data
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 2. Convert data to an HTML string
            guard let htmlString = String(data: data, encoding: .utf8) else {
                print("Could not decode HTML from: \(url)")
                return nil
            }
            
            // 3. Use SwiftSoup to parse the HTML
            let doc = try SwiftSoup.parse(htmlString)
            
            // 4. Get the clean text from the body (this strips all HTML tags)
            let cleanText = try doc.body()?.text()
            return cleanText
            
        } catch {
            print("Error scraping web page \(url): \(error.localizedDescription)")
            return nil
        }
    }
}
