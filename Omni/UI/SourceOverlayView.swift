import SwiftUI

struct SourceOverlayView: View {
    let sourceFileName: String
    
    var body: some View {
        Text(sourceFileName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color(hex: "3A3A3A")) // Darker background for the overlay
            .cornerRadius(5)
            .foregroundColor(.white)
            .shadow(radius: 3)
    }
}
