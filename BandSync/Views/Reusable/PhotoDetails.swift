

import SwiftUI
import UIKit
import Photos
import os.log

struct PhotoDetails: View {
    @Environment(\.dismiss) var dismiss
    let uiImage: UIImage
    private let logger = Logger(subsystem: "com.bandsync.app", category: "PhotoDetails")

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero
    @State private var showingPhotoSavedView = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                    Spacer()
                    
                    Button(action: { saveImage() }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding()
                    }
                }

                GeometryReader { imageProxy in
                    ZStack {
                        Color.white

                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: offset.x, y: offset.y)
                            .gesture(makeDragGesture(size: imageProxy.size))
                            .gesture(makeMagnificationGesture(size: imageProxy.size))
                            .onTapGesture(count: 2, perform: resetScale)
                    }
                }
                
                if showingPhotoSavedView {
                    PhotoSavedView()
                }
            }
            .background(Color.white)
        }
        .alert("Error".localized, isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

private extension PhotoDetails {
    func handleBackButtonTap() {
        dismiss()
    }

    func resetScale() {
        withAnimation {
            scale = 1
            offset = .zero
        }
    }

    func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value

                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    resetScale()
                }
                adjustMaxOffset(size: size)
            }
    }

    func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Disable drag when image hasn't been zoomed in
                guard scale != 1 else { return }
                
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }

    func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2

        var newOffsetX = offset.x
        var newOffsetY = offset.y

        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }

        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }

        lastTranslation = .zero
    }
    
    private func saveImage() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            writeImage()

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        writeImage()
                    } else {
                        showPermissionDeniedError()
                    }
                }
            }

        case .denied, .restricted:
            showPermissionDeniedError()
            
        @unknown default:
            logger.error("Unknown photo library authorization status")
            showGenericError()
        }
    }

    private func writeImage() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.creationRequestForAsset(from: uiImage)
        }) { [self] success, error in
            DispatchQueue.main.async {
                if success {
                    showImageSavedConfirmation()
                    logger.info("Image saved to photo library successfully")
                } else {
                    let errorDescription = error?.localizedDescription ?? "Unknown error"
                    logger.error("Failed to save image to photo library: \(errorDescription, privacy: .public)")
                    showSaveError(errorDescription)
                }
            }
        }
    }
    
    private func showImageSavedConfirmation() {
        showingPhotoSavedView = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingPhotoSavedView = false
        }
    }
    
    private func showPermissionDeniedError() {
        errorMessage = "Photo library access is required to save images. Please enable it in Settings."
        showingErrorAlert = true
        logger.warning("Photo library access denied by user")
    }
    
    private func showSaveError(_ description: String) {
        errorMessage = "Failed to save image: \(description)"
        showingErrorAlert = true
    }
    
    private func showGenericError() {
        errorMessage = "An unexpected error occurred while saving the image."
        showingErrorAlert = true
    }
}

#Preview {
    PhotoDetails(
        uiImage: UIImage(named: "bg") ?? UIImage()
    )
}
