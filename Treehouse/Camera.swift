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
import FirebaseFirestore

// MARK: - Camera View Controller

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    // Photo output for capturing images
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
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds

        view.layer.addSublayer(preview)
        self.captureSession = session
        self.previewLayer = preview

        session.startRunning()
    }
    
    // Trigger a photo capture
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // Delegate method: called when a photo is captured
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        onPhotoCaptured?(imageData)
    }
}

// MARK: - CameraPreview (UIViewControllerRepresentable)

struct CameraPreview: UIViewControllerRepresentable {
    var onPhotoCaptured: (Data) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.onPhotoCaptured = onPhotoCaptured
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Camera SwiftUI View

struct Camera: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var profileImageURL: String = ""
    @State private var navigateToGroupChat: Bool = false
    
    // Group document reference passed from Home
    var groupRef: DocumentReference?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Camera area (top ~84%)
                    ZStack {
                        CameraPreview { imageData in
                            // Once a photo is captured, upload and update group document
                            storePhotoInFirestore(imageData: imageData)
                        }
                        .frame(height: geo.size.height * 0.84)
                        .clipped()
                        
                        // Shutter button overlay
                        VStack {
                            Spacer()
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: Notification.Name("CapturePhoto"),
                                    object: nil
                                )
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                        .frame(width: 75, height: 75)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 65, height: 65)
                                        .shadow(radius: 5)
                                }
                            }
                            .padding(.bottom, 36)
                        }
                    }
                    
                    // Bottom black area with a placeholder caption
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Capsule()
                                .fill(Color.gray)
                                .frame(width: 290, height: 70)
                                .offset(y: -35)
                            
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
            .navigationDestination(isPresented: $navigateToGroupChat) {
                if let groupId = groupRef?.documentID {
                    GroupChat(groupId: groupId)
                } else {
                    // Optionally handle the error case or pass a default value
                    GroupChat(groupId: "")
                }
            }

            .onAppear {
                fetchUserInfo()
            }
        }
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
    
    // Fetch current user's info from Firestore
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
    
    // Upload the captured photo and update the group document's image URL
    private func storePhotoInFirestore(imageData: Data) {
        guard let uid = Auth.auth().currentUser?.uid,
              !username.isEmpty,
              !profileImageURL.isEmpty,
              let groupRef = groupRef else {
            print("No user info, not logged in, or groupRef missing.")
            return
        }
        
        let db = Firestore.firestore()
        let pictureRef = db.collection("users")
            .document(uid)
            .collection("Picture")
            .document()
        
        let storageRef = Storage.storage().reference()
            .child("pictures/\(uid)/\(pictureRef.documentID).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching download URL: \(error)")
                    return
                }
                guard let downloadURL = url else { return }
                
                // Update the existing group document with the photo URL
                groupRef.updateData(["groupImageURL": downloadURL.absoluteString]) { err in
                    if let err = err {
                        print("Error updating group image: \(err)")
                    } else {
                        print("Group image updated successfully.")
                        self.navigateToGroupChat = true
                    }
                }
            }
        }
    }
}

#Preview {
    Camera(groupRef: nil)
}
