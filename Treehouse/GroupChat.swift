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

// A model for each image the user sends
struct SentImage: Identifiable {
    let id = UUID()
    let uid: String
    let username: String
    let imageURL: String
}

struct GroupChat: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHome: Bool = false   // For navigation
    
    // We'll fetch all images from Firestore as "sentImages"
    @State private var sentImages: [SentImage] = []
    
    @State private var username: String = ""
    @State private var profileImageURL: String = ""
    
    // If you still want to keep track of group members:
    @State private var groupMembers: [String] = []
    
    let groupId: String   // Group document ID
    
    // Grid layout: 2 columns
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
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
                        .offset(x: 15)
                    
                    Spacer()
                    
                    Text("18:00")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer(minLength: 20)
                
                // 2x2 layout with one image top-left + 3 gray boxes (no ScrollView)
                LazyVGrid(columns: columns, spacing: 16) {
                    
                    // TOP-LEFT CELL: show first sent image if it exists
                    if let firstItem = sentImages.first {
                        ZStack(alignment: .topLeading) {
                            // The user's sent photo
                            AsyncImage(url: URL(string: firstItem.imageURL)) { phase in
                                if let img = phase.image {
                                    img.resizable()
                                        .scaledToFill()
                                } else if phase.error != nil {
                                    Image(systemName: "exclamationmark.triangle")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.red)
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 175, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .clipped()
                            
                            // Name bubble: profile pic + username
                            HStack(spacing: 6) {
                                AsyncImage(url: URL(string: profileImageURL)) { phase in
                                    if let img = phase.image {
                                        img.resizable()
                                            .scaledToFill()
                                    } else if phase.error != nil {
                                        Circle().fill(Color.gray)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                                
                                Text(username.isEmpty ? firstItem.username : username)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                            )
                            .padding(6)
                        }
                    } else {
                        // Fallback gray box if no first item
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 175, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // TOP-RIGHT CELL: gray box
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 175, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // BOTTOM-LEFT CELL: gray box
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 175, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // BOTTOM-RIGHT CELL: gray box
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 175, height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 10)
                
                // Bottom bar: "Waiting on..." with group members
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Waiting on...")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        HStack(spacing: -15) {
                            ForEach(groupMembers, id: \.self) { member in
                                AsyncImage(url: URL(string: member)) { phase in
                                    if let img = phase.image {
                                        img.resizable()
                                            .scaledToFill()
                                    } else if phase.error != nil {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 35, height: 35)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                        .frame(height: 35)
                    }
                    .padding(.horizontal, 42)
                    .padding(.vertical, 23)
                    .background(Color.white)
                    .cornerRadius(50)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
            }
            
            // Hidden NavigationLink for back navigation
            NavigationLink(destination: Home().navigationBarBackButtonHidden(true), isActive: $navigateToHome) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            fetchGroupDocument()
            fetchUserInfo()
        }
        // Once the current user's profile image is fetched, remove it from the waiting list (if that's still your UI).
        .onChange(of: profileImageURL) { newValue in
            if !newValue.isEmpty {
                self.groupMembers = self.groupMembers.filter { $0 != newValue }
            }
        }
    }
}

extension GroupChat {
    // Fetch the group document to retrieve "sentImages" and (optionally) "members"
    private func fetchGroupDocument() {
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
            guard let data = snapshot?.data() else { return }
            
            // 1) Parse the "sentImages" array of dictionaries
            if let sentImagesData = data["sentImages"] as? [[String: Any]] {
                let parsedImages = sentImagesData.compactMap { dict -> SentImage? in
                    guard
                        let uid = dict["uid"] as? String,
                        let username = dict["username"] as? String,
                        let imageURL = dict["imageURL"] as? String
                    else {
                        return nil
                    }
                    return SentImage(uid: uid, username: username, imageURL: imageURL)
                }
                self.sentImages = parsedImages
            }
            
            // 2) If you still want to track group members:
            self.groupMembers = data["members"] as? [String] ?? []
        }
    }
    
    // Fetch current user's info (username & profile image).
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
    GroupChat(groupId: "dummyGroupId")
}
