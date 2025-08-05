//
//  AboutView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 29.05.2025.
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @Environment(\.openURL) var openURL
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingCookiePolicy = false
    @State private var showingGDPRCompliance = false
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image("bandlogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BandSync")
                            .font(.body)
                            .fontWeight(.semibold)
                        
                        Text(String(format: NSLocalizedString("Version %@", comment: "App version display format"), getAppVersion()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            Section {
                FeatureRow(icon: "calendar", title: "Event Management", description: "Schedule rehearsals, gigs, and performances", color: .blue)
                FeatureRow(icon: "music.note.list", title: "Setlist Organization", description: "Create and manage your song lists", color: .purple)
                FeatureRow(icon: "dollarsign.circle", title: "Finance Tracking", description: "Monitor income and expenses", color: .green)
                FeatureRow(icon: "person.3", title: "Team Coordination", description: "Organize and coordinate with band members", color: .orange)
                FeatureRow(icon: "bag", title: "Merchandise", description: "Track inventory and sales", color: .brown)
            } header: {
                Text(NSLocalizedString("Key Features", comment: "Section header for app features"))
            }
            
            Section {
                NavigationLink(destination: HelpFAQView()) {
                    AboutRow(icon: "questionmark.circle", title: "Help & FAQ", color: .blue, showChevron: false)
                }
                
                Button(action: { contactSupport() }) {
                    AboutRow(icon: "envelope", title: "Contact Support", color: .green)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { openWebsite() }) {
                    AboutRow(icon: "globe", title: "Visit Website", color: .blue)
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text(NSLocalizedString("Support", comment: "Section header for support options"))
            }
            
            Section {
                Button(action: { showingPrivacyPolicy = true }) {
                    AboutRow(icon: "lock", title: "Privacy Policy", color: .blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingTermsOfService = true }) {
                    AboutRow(icon: "doc.text", title: "Terms of Service", color: .purple)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingCookiePolicy = true }) {
                    AboutRow(icon: "globe", title: "Cookie Policy", color: .orange)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingGDPRCompliance = true }) {
                    AboutRow(icon: "checkmark.shield.fill", title: "GDPR Compliance", color: .green)
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text(NSLocalizedString("Legal", comment: "Section header for legal documents"))
            } footer: {
                if let agreementDate = LegalConsentTracker.shared.getConsentDate() {
                    Text(String(format: NSLocalizedString("Terms agreed: %@", comment: "Shows when user agreed to terms"), DateFormatter.localizedString(from: agreementDate, dateStyle: .medium, timeStyle: .none)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(NSLocalizedString("Terms agreement required on next launch", comment: "Warning that terms agreement is needed"))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                VStack(spacing: 6) {
                    Text(NSLocalizedString("Made by musicians for musicians", comment: "App tagline"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("© 2025 BandSync", comment: "Copyright notice"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("All rights reserved.", comment: "Rights statement"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            } header: {
                Text(NSLocalizedString("About", comment: "Section header for about information"))
            }
        }
        .navigationTitle(NSLocalizedString("About BandSync", comment: "Navigation title for about screen"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to close sheet")) {
                                showingPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingTermsOfService) {
            NavigationView {
                TermsOfServiceView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to close sheet")) {
                                showingTermsOfService = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingCookiePolicy) {
            NavigationView {
                CookiePolicyView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to close sheet")) {
                                showingCookiePolicy = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingGDPRCompliance) {
            NavigationView {
                GDPRComplianceView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("Done", comment: "Button to close sheet")) {
                                showingGDPRCompliance = false
                            }
                        }
                    }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(title, comment: "Feature title"))
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(NSLocalizedString(description, comment: "Feature description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct AboutRow: View {
    let icon: String
    let title: String
    let color: Color
    let showChevron: Bool
    
    init(icon: String, title: String, color: Color, showChevron: Bool = true) {
        self.icon = icon
        self.title = title
        self.color = color
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(NSLocalizedString(title, comment: "About row title"))
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
    }
}

struct HelpFAQView: View {
    var body: some View {
        List {
            Section {
                FAQRow(question: "How do I create or join a band group?", answer: "When you first launch BandSync, choose 'Create Group' to start a new band or 'Join Group' with an invitation code from your band leader.")
                
                FAQRow(question: "What permissions do I have?", answer: "Your access depends on your role set by the band leader. You may have permissions for Calendar, Setlists, Finances, Merchandise, Tasks, Contacts, Documents, or Admin functions.")
            } header: {
                Text(NSLocalizedString("Getting Started", comment: "FAQ section for getting started"))
            }
            
            Section {
                FAQRow(question: "How do I create events?", answer: "Go to Calendar tab, tap + to create concerts, rehearsals, meetings, interviews, photoshoots, or personal events. Add location, fee, organizer contacts, and hotel details.")
                
                FAQRow(question: "Can I attach setlists to events?", answer: "Yes! When creating events, you can select an existing setlist to associate with that performance or rehearsal.")
            } header: {
                Text(NSLocalizedString("Calendar & Events", comment: "FAQ section for calendar and events"))
            }
            
            Section {
                FAQRow(question: "How do I create setlists?", answer: "In Setlists tab, tap + to create new setlists. Add songs with title, duration (minutes:seconds), BPM, and musical key. You can also import songs from existing setlists.")
                
                FAQRow(question: "Can I plan concert timing?", answer: "Yes! Enable concert timing when creating setlists. Set start time and duration - BandSync calculates song start times and break intervals automatically.")
                
                FAQRow(question: "How do I export setlists?", answer: "Open any setlist, tap the share button to export as PDF. Customize to include/exclude BPM, keys, and timing information.")
                
                FAQRow(question: "Can I reorder songs?", answer: "Yes! In edit mode, drag and drop songs to reorder. If using concert timing, all start times recalculate automatically.")
            } header: {
                Text(NSLocalizedString("Setlists & Music", comment: "FAQ section for setlists and music"))
            }
            
            Section {
                FAQRow(question: "How do I communicate with bandmates?", answer: "Use Tasks and Events to coordinate activities. Contact information is available in the Contacts section for direct communication.")
                
                FAQRow(question: "Can I create multiple project groups?", answer: "Yes! Create separate project groups for different topics - general coordination, business matters, or specific projects.")
            } header: {
                Text(NSLocalizedString("Communication", comment: "FAQ section for communication"))
            }
            
            Section {
                FAQRow(question: "How do I track income and expenses?", answer: "In Finances tab, add income (performances, merchandise, royalties) and expenses (logistics, accommodation, food, gear, promotion). View profit calculations automatically.")
                
                FAQRow(question: "Can I scan receipts?", answer: "Yes! Use the scan receipt feature to capture expense information from photos. The app can extract key details to speed up your bookkeeping.")
                
                FAQRow(question: "How do I manage merchandise?", answer: "Merch tab tracks inventory, prices, and sales across different channels (concerts, online, partners). Monitor low stock items and sales performance.")
            } header: {
                Text(NSLocalizedString("Finances & Business", comment: "FAQ section for finances and business"))
            }
            
            Section {
                FAQRow(question: "How do I assign tasks?", answer: "Tasks tab lets you create tasks with due dates, priorities, and assignments. Categories include rehearsal, performance, songwriting, booking, marketing, equipment, and more.")
                
                FAQRow(question: "How do I manage contacts?", answer: "Contacts tab organizes musicians, venues, managers, producers, and other industry professionals. Import from device contacts or add manually with roles.")
            } header: {
                Text(NSLocalizedString("Tasks & Organization", comment: "FAQ section for tasks and organization"))
            }
            
            Section {
                FAQRow(question: "How do I store documents?", answer: "Documents tab requires Google Drive connection to create and store documents. Connect your Google Drive account to access document management features.")
                
                FAQRow(question: "Do I need Google Drive?", answer: "Yes, Google Drive connection is required for the Documents feature. Without it, you can't create or store documents in the app.")
            } header: {
                Text(NSLocalizedString("Documents & Storage", comment: "FAQ section for documents and storage"))
            }
            
            Section {
                FAQRow(question: "How is my data synced?", answer: "All data automatically syncs to Firebase cloud storage in real-time. Changes appear instantly across all devices where band members are logged in.")
                
                FAQRow(question: "Can I work offline?", answer: "Yes! BandSync caches data locally. You can view and edit information offline - changes sync automatically when you reconnect.")
                
                FAQRow(question: "Is my data secure?", answer: "Yes! All data uses Firebase security with encryption. Optional Face ID/Touch ID authentication adds extra protection for sensitive information.")
            } header: {
                Text(NSLocalizedString("Data & Security", comment: "FAQ section for data and security"))
            }
            
            Section {
                FAQRow(question: "Why can't I edit certain things?", answer: "Your editing permissions are set by your band leader. Contact them if you need access to specific features like finances or merchandise management.")
                
                FAQRow(question: "The app seems slow. What should I do?", answer: "Check your internet connection. Clear app cache in Settings > Cache Management. If issues persist, try logging out and back in.")
                
                FAQRow(question: "How do I invite new members?", answer: "Band leaders can generate invitation codes in Settings > Account. Share this code with new members to join your group.")
            } header: {
                Text(NSLocalizedString("Troubleshooting", comment: "FAQ section for troubleshooting"))
            }
            
            Section {
                Button(action: { contactSupport() }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text(NSLocalizedString("Contact Support", comment: "Contact support button"))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text(NSLocalizedString("Need More Help?", comment: "FAQ section for additional help"))
            }
        }
        .navigationTitle(NSLocalizedString("Help & FAQ", comment: "Navigation title for help and FAQ"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(NSLocalizedString(question, comment: "FAQ question"))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(NSLocalizedString(answer, comment: "FAQ answer"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private func getAppVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}

private func getBuildNumber() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}

private func requestAppReview() {
    if #available(iOS 18.0, *) {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            Task {
                await AppStore.requestReview(in: scene)
            }
        }
    } else {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

private func contactSupport() {
    let emailParts = ["support", "@", "bandsync-app", ".", "com"]
    let email = emailParts.joined()
    if let url = URL(string: "mailto:\(email)?subject=BandSync Support") {
        UIApplication.shared.open(url)
    }
}

private func openWebsite() {
    let urlParts = ["http://", "bandsync-app", ".", "com"]
    let website = urlParts.joined()
    if let url = URL(string: website) {
        UIApplication.shared.open(url)
    }
}
