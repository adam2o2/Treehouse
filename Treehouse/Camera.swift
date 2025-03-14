//
//  Camera.swift
//  Treehouse
//
//  Created by Safiya May on 3/12/25.
//

import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseStorage

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    // Photo output for capturing still images
    let photoOutput = AVCapturePhotoOutput()
    
    // Closure to call when a photo is captured
    var onPhotoCaptured: ((Data) -> Void)?

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
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds

        view.layer.addSublayer(preview)
        self.captureSession = session
        self.previewLayer = preview

        // Start the session
        session.startRunning()
    }
    
    // Trigger a photo capture
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // AVCapturePhotoCaptureDelegate: handle captured photo
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        // Pass the image data back to SwiftUI
        onPhotoCaptured?(imageData)
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    // Closure to handle photo capture in SwiftUI
    var onPhotoCaptured: (Data) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onPhotoCaptured = onPhotoCaptured
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController,
                                context: Context) {
        // No updates needed
    }
}

struct Camera: View {
    @Environment(\.dismiss) private var dismiss
    
    // We’ll fetch username & profileImageURL from Firestore (not hardcoded)
    @State private var username: String = ""
    @State private var profileImageURL: String = ""
    
    // For navigation to GroupChat
    @State private var navigateToGroupChat: Bool = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    
                    // Camera area (top ~84%)
                    ZStack {
                        // Live camera feed
                        CameraPreview { imageData in
                            // Once a photo is captured, store in Firestore,
                            // then navigate to GroupChat
                            storePhotoInFirestore(imageData: imageData)
                        }
                        .frame(height: geo.size.height * 0.84)
                        .clipped()

                        // Place shutter button at bottom of camera feed
                        VStack {
                            Spacer()
                            Button(action: {
                                // Post notification to trigger capturePhoto()
                                NotificationCenter.default.post(
                                    name: Notification.Name("CapturePhoto"),
                                    object: nil
                                )
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
            // Navigation to GroupChat
            .navigationDestination(isPresented: $navigateToGroupChat) {
                GroupChat()
            }
            // Fetch user info from Firestore
            .onAppear {
                fetchUserInfo()
            }
        }
        // Listen for "CapturePhoto" notification to call capturePhoto()
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CapturePhoto"))) { _ in
            if let cameraVC = findCameraViewController() {
                cameraVC.capturePhoto()
            }
        }
    }
    
    // Recursively find the active CameraViewController
    private func findCameraViewController() -> CameraViewController? {
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        return searchForCameraVC(in: rootVC)
    }
    
    private func searchForCameraVC(in vc: UIViewController?) -> CameraViewController? {
        guard let vc = vc else { return nil }
        if let cameraVC = vc as? CameraViewController {
            return cameraVC
        }
        for child in vc.children {
            if let found = searchForCameraVC(in: child) {
                return found
            }
        }
        if let presented = vc.presentedViewController {
            return searchForCameraVC(in: presented)
        }
        return nil
    }
    
    // Fetch the user’s username & profileImageURL from Firestore
    private func fetchUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user info: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.username = data["username"] as? String ?? ""
            self.profileImageURL = data["profileImageURL"] as? String ?? ""
        }
    }
    
    // Store the captured photo in Firestore as a subcollection "Picture"
    private func storePhotoInFirestore(imageData: Data) {
        guard let uid = Auth.auth().currentUser?.uid,
              !username.isEmpty,
              !profileImageURL.isEmpty
        else {
            print("No user info or not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let pictureRef = db.collection("users")
            .document(uid)
            .collection("Picture")
            .document()
        
        // Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
            .child("pictures/\(uid)/\(pictureRef.documentID).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL: \(error)")
                    return
                }
                guard let downloadURL = url else { return }
                
                // Save doc in Firestore with user info
                let data: [String: Any] = [
                    "imageURL": downloadURL.absoluteString,
                    "username": self.username,
                    "profileImageURL": self.profileImageURL,
                    "timestamp": FieldValue.serverTimestamp()
                ]
                pictureRef.setData(data) { error in
                    if let error = error {
                        print("Error saving to Firestore: \(error)")
                    } else {
                        print("Successfully saved photo in subcollection 'Picture'")
                        // Navigate to GroupChat
                        self.navigateToGroupChat = true
                    }
                }
            }
        }
    }
}

#Preview {
    Camera()
}
