//
//  GroupChat.swift
//  Treehouse
//
//  Created by Safiya May on 3/13/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GroupChat: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHome: Bool = false   // For navigation
    
    @State private var groupImageURL: String = ""       // Fetched from the group doc
    @State private var username: String = ""
    @State private var profileImageURL: String = ""
    
    let groupId: String   // Group document ID passed from Home
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with a custom back button
                HStack {
                    Button(action: {
                        navigateToHome = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("Sassy Captions")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("18:00")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer(minLength: 20)
                
                // Main group image container
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 300, height: 450)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            AsyncImage(url: URL(string: groupImageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 300, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                    
                    // User's profile image + username overlay
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: profileImageURL)) { phase in
                            if let img = phase.image {
                                img.resizable()
                                    .scaledToFill()
                            } else {
                                Circle().fill(Color.gray)
                            }
                        }
                        .frame(width: 33, height: 33)
                        .clipShape(Circle())
                        
                        Text(username.isEmpty ? "Hasque" : username)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.8))
                    )
                    .offset(x: 14, y: 20)
                }
                
                Spacer(minLength: 30)
                
                // Bottom bar with a waiting status and a camera button
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Waiting on...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        ZStack {
                            circleView().offset(x: 35)
                            circleView().offset(x: 15)
                            circleView().offset(x: -5)
                        }
                        .offset(x: -1)
                        .frame(width: 65, height: 35)
                    }
                    .padding(.horizontal, 42)
                    .padding(.vertical, 23)
                    .background(Color.white)
                    .cornerRadius(50)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .offset(x: 10)
                    
                    Spacer()
                    
                    Button(action: {
                        // Add any camera logic if needed
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .padding(16)
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .offset(x: -5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            
            // Hidden NavigationLink for back navigation
            NavigationLink(destination: Home().navigationBarBackButtonHidden(true), isActive: $navigateToHome) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchGroupImage()
            fetchUserInfo()
        }
    }
}

extension GroupChat {
    // Helper view for a circle with a white stroke
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
    // Fetch the group document to retrieve the group's image URL
    private func fetchGroupImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users")
            .document(uid)
            .collection("groups")
            .document(groupId)
        
        docRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching group document: \(error)")
                return
            }
            if let data = snapshot?.data() {
                self.groupImageURL = data["groupImageURL"] as? String ?? ""
            }
        }
    }
    
    // Fetch current user's info (username & profile image)
    private func fetchUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user info: \(error)")
                return
            }
            if let data = snapshot?.data() {
                self.username = data["username"] as? String ?? ""
                self.profileImageURL = data["profileImageURL"] as? String ?? ""
            }
        }
    }
}

#Preview {
    // For preview purposes, pass a dummy groupId.
    GroupChat(groupId: "dummyGroupId")
}
