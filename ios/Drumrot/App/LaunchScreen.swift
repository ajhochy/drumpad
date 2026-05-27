import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.10, green: 0.11, blue: 0.14), location: 0.0),
                    .init(color: Color(red: 0.03, green: 0.04, blue: 0.05), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.36, green: 0.94, blue: 0.49).opacity(0.26),
                    .clear
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 620
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.16, blue: 0.48).opacity(0.28),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 80,
                endRadius: 680
            )
            .ignoresSafeArea()

            Image("LaunchMark")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .shadow(color: Color(red: 1.0, green: 0.16, blue: 0.48).opacity(0.36), radius: 28)
                .shadow(color: Color(red: 0.36, green: 0.94, blue: 0.49).opacity(0.24), radius: 42)
        }
        .background(Color(red: 0.03, green: 0.04, blue: 0.05))
    }
}

#Preview {
    LaunchScreen()
}
