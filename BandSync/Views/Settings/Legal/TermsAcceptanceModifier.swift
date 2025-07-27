import SwiftUI

struct TermsAcceptanceModifier: ViewModifier {
    @State private var showTermsAgreement = false
    @State private var hasCheckedTerms = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasCheckedTerms {
                    checkTermsAcceptance()
                    hasCheckedTerms = true
                }
            }
            .fullScreenCover(isPresented: $showTermsAgreement) {
                TermsAgreementView {
                    showTermsAgreement = false
                }
            }
    }
    
    private func checkTermsAcceptance() {
        if !TermsAgreementView.hasUserAgreedToTerms() {
            showTermsAgreement = true
        }
    }
}

extension View {
    func requireTermsAcceptance() -> some View {
        modifier(TermsAcceptanceModifier())
    }
}
