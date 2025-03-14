//
//  GroupChat.swift
//  Treehouse
//
//  Created by Safiya May on 3/13/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct GroupChat: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var latestImageURL: String = ""
    @State private var username: String = ""
    @State private var profileImageURL: String = ""
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    // Left chevron (custom back button)
                    Button(action: {
                        dismiss()  // Return to previous view
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Center: "Sassy Captions"
                    Text("Sassy Captions")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Right: "18:00"
                    Text("18:00")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer(minLength: 20)
                
                ZStack(alignment: .topLeading) {
                    
                    // Background rounded rectangle + the fetched image
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 300, height: 450)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            // The user's latest image from Firestore
                            AsyncImage(url: URL(string: latestImageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 300, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                    
                    // Top-left corner: user’s profile image + username (in white)
                    HStack(spacing: 6) {
                        // Profile image
                        AsyncImage(url: URL(string: profileImageURL)) { phase in
                            if let img = phase.image {
                                img.resizable()
                                    .scaledToFill()
                            } else {
                                Circle().fill(Color.gray)
                            }
                        }
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        
                        // Username in white
                        Text(username)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                }
                
                Spacer(minLength: 30)
                
                HStack(spacing: 12) {
                    
                    // Pill with "Waiting on..." + 3 circles
                    HStack(spacing: 8) {
                        Text("Waiting on...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        // ZStack to control overlap order:
                        // The right circle is drawn first (behind),
                        // the left circle is drawn last (on top).
                        ZStack {
                            // Right circle (behind)
                            circleView()
                                .offset(x: 35)
                            
                            // Middle circle
                            circleView()
                                .offset(x: 15)
                            
                            // Left circle (drawn last, so on top)
                            circleView()
                                .offset(x: -5)
                        }
                        .offset(x: -1)
                        .frame(width: 65, height: 35)
                    }
                    .padding(.horizontal, 42)
                    .padding(.vertical, 23)
                    .background(Color.white)
                    .cornerRadius(50)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .offset(x: 20)
                    
                    Spacer()
                    
                    // Camera icon in a pill
                    Button(action: {
                        // Add your camera logic here if needed
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .padding(16)
                    }
                    .frame(width: 70, height: 70)  // Adjust these values to change the circle size
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)  // Hide default back button
        .onAppear {
            fetchLatestPicture()
            fetchUserInfo()
        }
    }
}

extension GroupChat {
    // A single gray circle with a white stroke
    private func circleView() -> some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 35, height: 35)
            
            Circle()
                .fill(Color.gray)
                .frame(width: 35, height: 35)
        }
    }
}

extension GroupChat {
    // Fetch the most recent image from subcollection "Picture"
    private func fetchLatestPicture() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(uid)
            .collection("Picture")
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching latest picture: \(error)")
                    return
                }
                guard let doc = snapshot?.documents.first else { return }
                let data = doc.data()
                self.latestImageURL = data["imageURL"] as? String ?? ""
            }
    }
    
    // Fetch user info (username, profileImageURL) from Firestore
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
}

#Preview {
    GroupChat()
}
