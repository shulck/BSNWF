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
                        Text(String.localizedStringWithFormat(NSLocalizedString("userIsTyping", comment: "User is typing..."), typingUsers.first!))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if typingUsers.count == 2 {
                        Text(String.localizedStringWithFormat(NSLocalizedString("twoUsersAreTyping", comment: "X and Y are typing..."), typingUsers[0], typingUsers[1]))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String.localizedStringWithFormat(NSLocalizedString("multipleUsersAreTyping", comment: "X people are typing..."), typingUsers.count))
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
            TypingIndicatorView(typingUsers: [NSLocalizedString("previewUserAlex", comment: "Preview user Alex")])
                .previewDisplayName(NSLocalizedString("singleUser", comment: "Single user preview"))
            
            TypingIndicatorView(typingUsers: [NSLocalizedString("previewUserAlex", comment: "Preview user Alex"), NSLocalizedString("previewUserMaria", comment: "Preview user Maria")])
                .previewDisplayName(NSLocalizedString("twoUsers", comment: "Two users preview"))
            
            TypingIndicatorView(typingUsers: [NSLocalizedString("previewUserAlex", comment: "Preview user Alex"), NSLocalizedString("previewUserMaria", comment: "Preview user Maria"), NSLocalizedString("previewUserJohn", comment: "Preview user John"), NSLocalizedString("previewUserAnna", comment: "Preview user Anna")])
                .previewDisplayName(NSLocalizedString("multipleUsers", comment: "Multiple users preview"))
            
            TypingIndicatorView(typingUsers: [])
                .previewDisplayName(NSLocalizedString("nobodyTyping", comment: "Nobody typing preview"))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
