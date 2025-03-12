//
//  Profile.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct Profile: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // State variable to trigger navigation to Username
    @State private var navigateToUsername = false
    // Holds the user-selected image.
    @State private var selectedImage: UIImage? = nil
    // Controls presentation of the image picker.
    @State private var showImagePicker = false
    // Flag to show an uploading indicator.
    @State private var isUploading = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 40)
                    
                    // Title
                    Text("Upload a profile photo")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .offset(y: -150)

                    // Profile Image Circle: shows the selected image (if available) or a default person icon.
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 160, height: 160)
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    // Tapping the circle opens the image picker.
                    .onTapGesture {
                        showImagePicker = true
                    }

                    Spacer()
                    
                    // "Upload a profile picture" button
                    Button(action: {
                        uploadImage()
                    }) {
                        HStack {
                            Spacer()
                            if isUploading {
                                ProgressView()
                            } else {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            Spacer()
                        }
                    }
                    .frame(width: sizeClass == .compact ? 291 : 400,
                           height: sizeClass == .compact ? 62 : 70)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(sizeClass == .compact ? 40 : 50)
                    .shadow(radius: 24, x: 0, y: 14)
                    .padding(.bottom, sizeClass == .compact ? 20 : 30)
                    .disabled(selectedImage == nil || isUploading)
                }

                // NavigationLink that becomes active after a successful upload.
                NavigationLink(destination: Username().navigationBarBackButtonHidden(true),
                               isActive: $navigateToUsername) {
                    EmptyView()
                }
                .hidden()
            }
            // Present the image picker sheet.
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }

    // Upload the image to Firebase Storage, then save its URL in Firestore.
    func uploadImage() {
        // Ensure we have image data and a valid UID.
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8),
              let uid = Auth.auth().currentUser?.uid else {
            print("Image not available or user not authenticated")
            return
        }
        
        isUploading = true
        
        // Create a reference to Firebase Storage.
        let storageRef = Storage.storage().reference().child("profile_images/\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                isUploading = false
                return
            }
            
            // Get the download URL for the uploaded image.
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    isUploading = false
                    return
                }
                
                guard let downloadURL = url else {
                    isUploading = false
                    return
                }
                
                // Save the download URL in Firestore under the user's document.
                let db = Firestore.firestore()
                db.collection("users").document(uid).setData(["profileImageURL": downloadURL.absoluteString], merge: true) { error in
                    isUploading = false
                    if let error = error {
                        print("Firestore error: \(error.localizedDescription)")
                    } else {
                        // Navigate to the next screen after successful upload.
                        navigateToUsername = true
                    }
                }
            }
        }
    }
}

// A SwiftUI wrapper for UIImagePickerController.
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
         let picker = UIImagePickerController()
         picker.delegate = context.coordinator
         picker.allowsEditing = false
         return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed.
    }
    
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
         let parent: ImagePicker
         init(_ parent: ImagePicker) {
              self.parent = parent
         }
         
         func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
              if let image = info[.originalImage] as? UIImage {
                   parent.selectedImage = image
              }
              parent.presentationMode.wrappedValue.dismiss()
         }
         
         func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
             parent.presentationMode.wrappedValue.dismiss()
         }
    }
}

#Preview {
    Profile()
}
