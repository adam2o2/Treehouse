//
//  Camera.swift
//  Treehouse
//
//  Created by Safiya May on 3/12/25.
//

import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds

        view.layer.addSublayer(preview)
        self.captureSession = session
        self.previewLayer = preview

        // Start the session
        session.startRunning()
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No updates needed for a basic preview
    }
}

struct Camera: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Camera area (top ~70%)
                ZStack {
                    // Live camera feed
                    CameraPreview()
                        .frame(height: geo.size.height * 0.84)
                        .clipped()

                    // Place shutter button at bottom of camera feed
                    VStack {
                        Spacer()
                        Button(action: {
                            // Capture logic here
                        }) {
                            ZStack {
                                // Outer circle with stroke
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 75, height: 75)
                                
                                // Inner circle
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.bottom, 36)
                    }

                }

                // Bottom black box (~30%)
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        // Gray Capsule as its own element
                        Capsule()
                            .fill(Color.gray)
                            .frame(width: 290, height: 70)
                            .offset(y: -35)
                        
                        // Sassy Captions text
                        Text("Sassy Captions")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .offset(y: -101)
                    }
                    
                }

                .frame(height: geo.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Camera()
}
