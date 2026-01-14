import SwiftUI

struct AppTheme {
    struct Colors {
        // Backgrounds
        static let backgroundStart = Color(hex: "134E4A") // teal-900
        static let backgroundMiddle = Color(hex: "115E59") // teal-800
        static let backgroundEnd = Color(hex: "064E3B")   // emerald-900
        static let listHeader = Color(hex: "064E3B").opacity(0.9)
        
        // Interactive Elements
        static let primaryButton = Color(hex: "14B8A6")   // teal-500
        static let primaryButtonHover = Color(hex: "0D9488")
        
        // Accents & Text
        static let accent = Color(hex: "5EEAD4")          // teal-300
        static let selection = Color(hex: "2DD4BF")       // teal-400
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)
        
        // System
        static let success = Color.green
        static let error = Color.red
    }
    
    struct Gradients {
        static let mainBackground = LinearGradient(
            colors: [
                Colors.backgroundStart,
                Colors.backgroundMiddle,
                Colors.backgroundEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
