import SwiftUI

// View for individual event row
struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(hex: event.type.color))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Event rating on the right side of the title
                    if let rating = event.rating {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                HStack {
                    Text(event.type.rawValue.localized)
                        .font(.caption)
                        .padding(3)
                        .padding(.horizontal, 3)
                        .background(Color(hex: event.type.color).opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(event.status.rawValue.localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let location = event.location, !location.isEmpty {
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
