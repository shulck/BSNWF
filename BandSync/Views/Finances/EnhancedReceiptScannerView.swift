import SwiftUI
import VisionKit
import Vision
import NaturalLanguage

struct ScanResult {
    var amount: Double?
    var date: Date?
    var merchantName: String?
    var category: String?
    var details: String
    var items: [String]
}

struct EnhancedReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var financeService = FinanceService.shared

    var externalRecognizedText: Binding<String>?
    var externalExtractedFinanceRecord: Binding<FinanceRecord?>?
    var onScanComplete: ((String?, ScanResult?) -> Void)?

    @State private var recognizedText = ""
    @State private var extractedAmount: Double?
    @State private var extractedDate: Date?
    @State private var extractedMerchant: String?
    @State private var extractedCategory: String?
    @State private var extractedItems: [String] = []
    @State private var scannedImage: UIImage?
    @State private var isScanning = false
    @State private var isProcessing = false
    @State private var isUploadingToFirebase = false
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var errorMessage: String?
    @State private var uploadProgress: Double = 0.0

    init(recognizedText: Binding<String>? = nil,
         extractedFinanceRecord: Binding<FinanceRecord?>? = nil,
         onScanComplete: ((String?, ScanResult?) -> Void)? = nil) {
        self.externalRecognizedText = recognizedText
        self.externalExtractedFinanceRecord = extractedFinanceRecord
        self.onScanComplete = onScanComplete
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    if isUploadingToFirebase {
                        uploadingView
                    }
                    
                    if !isUploadingToFirebase && !isProcessing {
                        scanButtons
                            .padding()
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if let amount = extractedAmount {
                        resultsView(amount: amount)
                    }
                    
                    Spacer()
                }
                
                if isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle(NSLocalizedString("Scan Receipt", comment: "Scan receipt navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                    .disabled(isUploadingToFirebase)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            VNDocumentCameraScannerView(recognizedText: $recognizedText, scannedImage: $scannedImage) { text in
                processRecognizedText(text: text)
            }
        }
        .sheet(isPresented: $showGallery) {
            ReceiptImagePicker(recognizedText: $recognizedText, scannedImage: $scannedImage) { text in
                processRecognizedText(text: text)
            }
        }
        .onChange(of: recognizedText) { _, newValue in
            externalRecognizedText?.wrappedValue = newValue
        }
    }

    private var uploadingView: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("Uploading to cloud storage", comment: "Uploading to cloud storage message"))
                .font(.headline)
                .foregroundColor(.blue)
            
            ProgressView(value: uploadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
                .scaleEffect(x: 1, y: 2)
            
            Text("\(Int(uploadProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func resultsView(amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Extracted Results", comment: "Extracted results title"))
                .font(.headline)
                .foregroundColor(.green)
            
            Text(String(format: NSLocalizedString("amount: €%.2f", comment: "Amount result format"), amount))
            
            if let merchant = extractedMerchant {
                Text(String(format: NSLocalizedString("merchant: %@", comment: "Merchant result format"), merchant))
            }
            
            if let category = extractedCategory {
                Text(String(format: NSLocalizedString("category: %@", comment: "Category result format"), category))
            }
            
            if isUploadingToFirebase {
                Text(NSLocalizedString("Uploading receipt to cloud storage", comment: "Uploading receipt message"))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            } else {
                Text(NSLocalizedString("Scanner will close automatically", comment: "Scanner auto-close message"))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
                
                Text(NSLocalizedString("Or use manual save", comment: "Manual save option message"))
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Button(NSLocalizedString("Manual Save", comment: "Manual save button")) {
                    forceSaveTransaction()
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isUploadingToFirebase)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text(NSLocalizedString("Analyzing receipt", comment: "Analyzing receipt progress message"))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
        }
    }

    private var scanButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                showCamera = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text(NSLocalizedString("Scan with Camera", comment: "Scan with camera button"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isUploadingToFirebase)

            Button(action: {
                showGallery = true
            }) {
                HStack {
                    Image(systemName: "photo")
                    Text(NSLocalizedString("Choose from Gallery", comment: "Choose from gallery button"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isUploadingToFirebase)
        }
    }

    private func resetState() {
        recognizedText = ""
        extractedAmount = nil
        extractedDate = nil
        extractedMerchant = nil
        extractedCategory = nil
        extractedItems = []
        scannedImage = nil
        isProcessing = false
        isUploadingToFirebase = false
        errorMessage = nil
        uploadProgress = 0.0
    }

    private func processRecognizedText(text: String) {
        guard !isProcessing && !isUploadingToFirebase else {
            return
        }
        
        isProcessing = true
        recognizedText = text

        DispatchQueue.global(qos: .userInitiated).async {
            let receiptData = ReceiptAnalyzer.analyze(text: text)

            DispatchQueue.main.async {
                extractedAmount = receiptData.amount
                extractedDate = receiptData.date
                extractedMerchant = receiptData.merchantName
                extractedCategory = receiptData.category
                extractedItems = receiptData.items

                var detailsText = ""
                if let merchant = receiptData.merchantName {
                    detailsText += merchant
                }
                if !receiptData.items.isEmpty {
                    if !detailsText.isEmpty {
                        detailsText += "\n"
                    }
                    detailsText += receiptData.items.prefix(3).joined(separator: "\n")
                    if receiptData.items.count > 3 {
                        detailsText += "\n..."
                    }
                }

                if receiptData.amount != nil,
                   AppState.shared.user?.groupId != nil {
                    let recordId = UUID().uuidString
                    uploadReceiptImageToFirebase(recordId: recordId, detailsText: detailsText, receiptData: receiptData)
                } else {
                    isProcessing = false
                    errorMessage = NSLocalizedString("Failed to extract amount or groupId", comment: "Failed to extract amount or groupId error")
                }
            }
        }
    }

    private func uploadReceiptImageToFirebase(recordId: String, detailsText: String, receiptData: ReceiptAnalyzer.ReceiptData) {
        guard let image = scannedImage,
              receiptData.amount != nil,
              AppState.shared.user?.groupId != nil else {
            completeWithoutFirebase(recordId: recordId, detailsText: detailsText, receiptData: receiptData)
            return
        }
        
        isUploadingToFirebase = true
        uploadProgress = 0.0
        
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if uploadProgress < 0.9 {
                uploadProgress += 0.05
            }
        }
        
        FirebaseStorageService.shared.uploadReceiptImage(image, recordId: recordId) { firebaseURL in
            DispatchQueue.main.async {
                progressTimer.invalidate()
                uploadProgress = 1.0
                isUploadingToFirebase = false
                
                if let firebaseURL = firebaseURL {
                    completeWithFirebaseURL(firebaseURL, recordId: recordId, detailsText: detailsText, receiptData: receiptData)
                } else {
                    completeWithoutFirebase(recordId: recordId, detailsText: detailsText, receiptData: receiptData)
                }
            }
        }
    }

    private func completeWithFirebaseURL(_ firebaseURL: String, recordId: String, detailsText: String, receiptData: ReceiptAnalyzer.ReceiptData) {
        guard let amountValue = receiptData.amount,
              let groupId = AppState.shared.user?.groupId else {
            return
        }
        
        let record = FinanceRecord(
            id: recordId,
            type: .expense,
            amount: amountValue,
            currency: "EUR",
            category: "Other",
            details: detailsText,
            date: receiptData.date ?? Date(),
            receiptUrl: firebaseURL,
            groupId: groupId
        )
        
        externalExtractedFinanceRecord?.wrappedValue = record
        
        if let onScanComplete = onScanComplete {
            let scanResult = ScanResult(
                amount: amountValue,
                date: receiptData.date,
                merchantName: receiptData.merchantName,
                category: receiptData.category,
                details: detailsText,
                items: receiptData.items
            )
            onScanComplete(firebaseURL, scanResult)
            isProcessing = false
            dismiss()
        } else {
            isProcessing = false
        }
    }

    private func completeWithoutFirebase(recordId: String, detailsText: String, receiptData: ReceiptAnalyzer.ReceiptData) {
        guard let image = scannedImage,
              let amountValue = receiptData.amount,
              let groupId = AppState.shared.user?.groupId else {
            return
        }
        
        let receiptPath = ReceiptStorage.saveReceipt(image: image, recordId: recordId)
        
        let record = FinanceRecord(
            id: recordId,
            type: .expense,
            amount: amountValue,
            currency: "EUR",
            category: "Other",
            details: detailsText,
            date: receiptData.date ?? Date(),
            receiptUrl: receiptPath,
            groupId: groupId
        )
        
        externalExtractedFinanceRecord?.wrappedValue = record
        
        if let onScanComplete = onScanComplete {
            let scanResult = ScanResult(
                amount: amountValue,
                date: receiptData.date,
                merchantName: receiptData.merchantName,
                category: receiptData.category,
                details: detailsText,
                items: receiptData.items
            )
            onScanComplete(receiptPath, scanResult)
            isProcessing = false
            dismiss()
        } else {
            isProcessing = false
        }
    }

    private func forceSaveTransaction() {
        guard let amountValue = extractedAmount,
              let groupId = AppState.shared.user?.groupId else {
            return
        }
        
        let recordId = UUID().uuidString
        
        if let image = scannedImage {
            isUploadingToFirebase = true
            FirebaseStorageService.shared.uploadReceiptImage(image, recordId: recordId) { firebaseURL in
                DispatchQueue.main.async {
                    isUploadingToFirebase = false
                    
                    let receiptPath = firebaseURL ?? ReceiptStorage.saveReceipt(image: image, recordId: recordId)
                    createAndSaveRecord(recordId: recordId, receiptPath: receiptPath, amountValue: amountValue, groupId: groupId)
                }
            }
        } else {
            createAndSaveRecord(recordId: recordId, receiptPath: nil, amountValue: amountValue, groupId: groupId)
        }
    }

    private func createAndSaveRecord(recordId: String, receiptPath: String?, amountValue: Double, groupId: String) {
        let record = FinanceRecord(
            id: recordId,
            type: .expense,
            amount: amountValue,
            currency: "EUR",
            category: extractedCategory ?? "Other",
            details: extractedMerchant ?? "Scanned receipt",
            date: extractedDate ?? Date(),
            receiptUrl: receiptPath,
            groupId: groupId
        )
        
        FinanceService.shared.add(record) { success in
            DispatchQueue.main.async {
                if success {
                    dismiss()
                } else {
                    errorMessage = NSLocalizedString("Failed to save transaction", comment: "Failed to save transaction error")
                }
            }
        }
    }
}

struct VNDocumentCameraScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var scannedImage: UIImage?
    var onTextRecognized: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: VNDocumentCameraScannerView

        init(_ parent: VNDocumentCameraScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                DispatchQueue.main.async {
                    controller.dismiss(animated: true)
                }
                return
            }

            let image = scan.imageOfPage(at: 0)
            parent.scannedImage = image
            recognizeText(from: image)
            
            DispatchQueue.main.async {
                controller.dismiss(animated: true)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            DispatchQueue.main.async {
                controller.dismiss(animated: true)
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            DispatchQueue.main.async {
                controller.dismiss(animated: true)
            }
        }

        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else {
                return
            }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      error == nil else {
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                DispatchQueue.main.async {
                    self.parent.recognizedText = text
                    self.parent.onTextRecognized(text)
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            DispatchQueue.global(qos: .userInitiated).async {
                try? requestHandler.perform([request])
            }
        }
    }
}

struct ReceiptImagePicker: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Binding var scannedImage: UIImage?
    var onTextRecognized: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReceiptImagePicker

        init(_ parent: ReceiptImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.scannedImage = image
                recognizeText(from: image)
            }

            DispatchQueue.main.async {
                picker.dismiss(animated: true)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            DispatchQueue.main.async {
                picker.dismiss(animated: true)
            }
        }

        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else {
                return
            }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      error == nil else {
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                DispatchQueue.main.async {
                    self.parent.recognizedText = text
                    self.parent.onTextRecognized(text)
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            DispatchQueue.global(qos: .userInitiated).async {
                try? requestHandler.perform([request])
            }
        }
    }
}
