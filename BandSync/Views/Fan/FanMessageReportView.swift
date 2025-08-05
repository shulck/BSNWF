import SwiftUI

// MARK: - FAN MESSAGE REPORT VIEW

struct FanMessageReportView: View {
    let message: FanMessage
    let chat: FanChat
    
    @StateObject private var fanChatService = FanChatService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedReason: FanChatReport.ReportReason = .spam
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Message Preview
                        messagePreviewSection
                        
                        // Report Reason Selection
                        reasonSelectionSection
                        
                        // Additional Details
                        additionalDetailsSection
                        
                        // Warning Notice
                        warningNoticeSection
                    }
                    .padding()
                }
                
                // Submit Button
                submitButtonSection
            }
            .navigationTitle(NSLocalizedString("Report Message", comment: "Navigation title for message report screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in report message screen")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("Report Submitted", comment: "Alert title when report is submitted"), isPresented: $showingConfirmation) {
                Button(NSLocalizedString("OK", comment: "OK button in report submitted alert")) {
                    dismiss()
                }
            } message: {
                Text(NSLocalizedString("Thank you for helping keep our community safe. We'll review this report and take appropriate action.", comment: "Message in report submitted alert"))
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "flag.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("Report Inappropriate Content", comment: "Title for report content screen"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("Help us maintain a positive community environment", comment: "Subtitle for report content screen"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Message Preview Section
    
    private var messagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Reported Message", comment: "Header for reported message section"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Text(String(message.displayName.prefix(1)).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Reason Selection Section
    
    private var reasonSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Why are you reporting this message?", comment: "Question for report reason selection"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(FanChatReport.ReportReason.allCases, id: \.self) { reason in
                    ReportReasonCard(
                        reason: reason,
                        isSelected: selectedReason == reason
                    ) {
                        selectedReason = reason
                    }
                }
            }
        }
    }
    
    // MARK: - Additional Details Section
    
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Additional Details (Optional)", comment: "Header for additional details section"))
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField(NSLocalizedString("Provide more context about why this message violates community rules...", comment: "Placeholder for additional details text field"), text: $additionalDetails, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
    }
    
    // MARK: - Warning Notice Section
    
    private var warningNoticeSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Important Notice", comment: "Header for important notice section"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text(NSLocalizedString("False reports may result in restrictions on your account. Only report content that genuinely violates our community rules.", comment: "Warning text about false reports"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Submit Button Section
    
    private var submitButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: submitReport) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "flag.fill")
                    }
                    
                    Text(isSubmitting ? NSLocalizedString("Submitting Report...", comment: "Text shown while submitting report") : NSLocalizedString("Submit Report", comment: "Button to submit report"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isSubmitting)
        }
        .padding()
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func submitReport() {
        isSubmitting = true
        
        fanChatService.reportMessage(
            message.id ?? "",
            in: chat.id ?? "",
            reason: selectedReason,
            description: additionalDetails.isEmpty ? nil : additionalDetails
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            showingConfirmation = true
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Report Reason Card

struct ReportReasonCard: View {
    let reason: FanChatReport.ReportReason
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.red : Color.red.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: reason.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .red)
                }
                
                Text(reason.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .red : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.red.opacity(0.1) : (colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
