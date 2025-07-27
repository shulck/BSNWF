//
//  SetlistExportView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI
import PDFKit

struct SetlistExportView: View {
    // Store a copy of the setlist to prevent reference issues
    @State private var localSetlist: Setlist
    @State private var pdfData: Data?
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    // Export parameters
    @State private var showBPM = true
    @State private var showKey = false
    
    // Initialize with a copy of the original setlist
    init(setlist: Setlist) {
        _localSetlist = State(initialValue: setlist)
    }
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header с иконкой
                    headerView
                    
                    // PDF Preview Card
                    pdfPreviewCard
                    
                    // Export Settings Card
                    exportSettingsCard
                    

                    
                    // Action Buttons Card
                    actionButtonsCard
                    
                    // Error Message
                    if let error = errorMessage {
                        errorView(error)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Export Setlist".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                closeButton
            }
        }
        .overlay {
            if isExporting {
                loadingOverlay
            }
        }
        .onAppear {
            generatePDF()
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                DocumentShareSheet(items: [pdfData])
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Export To PDF".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create A Professional Setlist Document".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - PDF Preview Card
    private var pdfPreviewCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("PDF Preview".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if pdfData != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Preview Content
            if let pdfData = pdfData, let pdfDocument = PDFDocument(data: pdfData) {
                VStack(spacing: 12) {
                    // Preview container
                    PDFDocumentPreviewView(document: pdfDocument)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .clipped()
                    
                    // PDF Info
                    VStack(spacing: 4) {
                        Text("Document Ready".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("PDF Generated Successfully".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 4) {
                                Text("PDF Preview".localized)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Generating Document".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Setlist Info
                    VStack(spacing: 8) {
                        Text("Setlist: \(localSetlist.name)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("\(localSetlist.songs.count) " + String.ukrainianSongsPlural(count: localSetlist.songs.count) + " • \(localSetlist.formattedTotalDuration)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Export Settings Card
    private var exportSettingsCard: some View {
        VStack(spacing: 0) {
            // Header карточки
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("Export Settings".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Show BPM Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show BPM".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Include BPM Information For Each Song".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $showBPM)
                        .labelsHidden()
                        .onChange(of: showBPM) {
                            generatePDF()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(showBPM ? Color.green.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
                
                // Show Key Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Musical Key".localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Include Key Signatures Where Available".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $showKey)
                        .labelsHidden()
                        .onChange(of: showKey) {
                            generatePDF()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(showKey ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    

    
    // MARK: - Action Buttons Card
    private var actionButtonsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Actions".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Update PDF Button
                Button {
                    generatePDF()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                        
                        Text("Update PDF".localized)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                
                // Share Button
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                        
                        Text("Share PDF".localized)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: pdfData == nil ? [Color.gray, Color.gray] : [Color.green, Color.teal]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: pdfData == nil ? Color.clear : Color.green.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .disabled(pdfData == nil)
                .opacity(pdfData == nil ? 0.6 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Close Button
    private var closeButton: some View {
        Button("Close") {
            dismiss()
        }
        .font(.body)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Creating PDF".localized)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Export Error".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    // Generate PDF
    private func generatePDF() {
        isExporting = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let options = SetlistPDFExporter.ExportOptions(
                showBPM: self.showBPM,
                showKey: self.showKey
            )
            
            let generatedPDF = SetlistPDFExporter.export(setlist: self.localSetlist, options: options)
            
            DispatchQueue.main.async {
                self.isExporting = false
                
                if let pdf = generatedPDF {
                    self.pdfData = pdf
                } else {
                    self.errorMessage = "Failed to create PDF. Please try again."
                }
            }
        }
    }
}
