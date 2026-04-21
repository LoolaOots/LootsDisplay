import SwiftUI

struct PremiumBadge: View {
    var body: some View {
        Text("badge.premium")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                LinearGradient(
                    colors: [Color(hex: "7B2FBE"), Color(hex: "BF5AF2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "BF5AF2").opacity(0.4), radius: 3, x: 0, y: 1)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    HStack {
        Text("btn.find_witmotion_sensor")
            .foregroundColor(.blue)
        Spacer()
        PremiumBadge()
    }
    .padding()
}
