import SwiftUI

// View for individual event row (Fan version)
struct FanEventRowView: View {
    let event: Event
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(hex: event.type.colorHex))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Special "Congratulate" text for birthday events
                    if event.type == .birthday {
                        HStack(spacing: 4) {
                            Text("🎉")
                                .font(.caption)
                            Text("Congratulate".localized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.pink)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                HStack {
                    Text(event.type.rawValue.localized)
                        .font(.caption)
                        .padding(3)
                        .padding(.horizontal, 3)
                        .background(Color(hex: event.type.colorHex).opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(event.status.rawValue.localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Show location only for non-birthday events
                if event.type != .birthday, let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
