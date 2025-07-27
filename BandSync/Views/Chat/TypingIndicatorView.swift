import SwiftUI

struct TypingIndicatorView: View {
    let typingUsers: [String]
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        if !typingUsers.isEmpty {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.0 + animationOffset * (index == 1 ? 0.5 : index == 2 ? 0.3 : 0.1))
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: animationOffset
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 2) {
                    if typingUsers.count == 1 {
                        Text("\(typingUsers.first!) \("is typing...".localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if typingUsers.count == 2 {
                        Text("\(typingUsers[0]) \("and".localized) \(typingUsers[1]) \("are typing...".localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(typingUsers.count) \("people are typing...".localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            ))
            .onAppear {
                animationOffset = 1.0
            }
            .onDisappear {
                animationOffset = 0.0
            }
        }
    }
}

struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TypingIndicatorView(typingUsers: ["Alex"])
                .previewDisplayName("Single user")
            
            TypingIndicatorView(typingUsers: ["Alex", "Maria"])
                .previewDisplayName("Two users")
            
            TypingIndicatorView(typingUsers: ["Alex", "Maria", "John", "Anna"])
                .previewDisplayName("Multiple users")
            
            TypingIndicatorView(typingUsers: [])
                .previewDisplayName("Nobody typing")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
