//
//  JoinGroupView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct JoinGroupView: View {
    @StateObject private var viewModel = GroupViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Group code", comment: "Header for group code input section"))) {
                    TextField(NSLocalizedString("Enter invitation code", comment: "Placeholder for invitation code input field"), text: $viewModel.groupCode)
                        .autocapitalization(.allCharacters)
                }
                
                Section {
                    Button(NSLocalizedString("Join", comment: "Button to join a group")) {
                        joinGroup()
                    }
                    .disabled(viewModel.groupCode.isEmpty || viewModel.isLoading)
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if let success = viewModel.successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Join Group", comment: "Navigation title for join group screen"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in join group screen")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func joinGroup() {
        viewModel.joinGroup { result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    appState.refreshAuthState()
                    dismiss()
                }
            case .failure:
                // Error will already be displayed through viewModel.errorMessage
                break
            }
        }
    }
}
