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
                Section(header: Text("Group code".localized)) {
                    TextField("Enter invitation code".localized, text: $viewModel.groupCode)
                        .autocapitalization(.allCharacters)
                }
                
                Section {
                    Button("Join".localized) {
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
            .navigationTitle("Join Group".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
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
