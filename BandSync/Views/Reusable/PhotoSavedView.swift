

import SwiftUI

struct PhotoSavedView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Image saved".localized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: true)
    }
}

#Preview {
    VStack {
        Spacer()
        HStack {
            Spacer()
            PhotoSavedView()
            Spacer()
        }
        Spacer()
    }
    .background(Color.white)
}
