import SwiftUI

struct AppTheme {
    struct Colors {
        // Backgrounds
        static let backgroundStart = Color(hex: "134E4A") // teal-900
        static let backgroundMiddle = Color(hex: "115E59") // teal-800
        static let backgroundEnd = Color(hex: "064E3B")   // emerald-900
        static let listHeader = Color(hex: "064E3B").opacity(0.9)
        static let darkBackground = Color(hex: "022c22")  // Used in DebriefFeedView
        
        // Interactive Elements
        static let primaryButton = Color(hex: "14B8A6")   // teal-500
        static let primaryButtonHover = Color(hex: "0D9488")
        
        // Accents & Text
        static let accent = Color(hex: "5EEAD4")          // teal-300
        static let selection = Color(hex: "2DD4BF")       // teal-400
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.4)
        
        // Semantic States
        static let success = Color.green
        static let error = Color.red
        static let trendPositive = Color(hex: "34D399")   // emerald-400
        static let trendNegative = Color(hex: "F87171")   // red-400
        static let warning = Color(hex: "FECACA")         // Light red
        
        // Extended Palette
        static let teal200 = Color(hex: "99F6E4")
        static let teal700 = Color(hex: "0F766E")
        static let cyan500 = Color(hex: "06B6D4")
        static let cyan600 = Color(hex: "0891B2")
        static let darkGray = Color(hex: "1F2937")
        static let purple = Color(hex: "A855F7")         // purple-500
        static let background = Color(hex: "022c22")      // Consistent dark bg
        static let secondaryBackground = Color(hex: "064E3B") // Slightly lighter
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
