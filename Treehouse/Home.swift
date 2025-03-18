//
//  Home.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct User: Identifiable {
    let id: String
    let name: String
    let profileImageURL: String
}

struct GroupModel: Identifiable {
    let id: String
    let groupName: String
    let groupImageURL: String
    let memberImageURLs: [String]
    let memberCount: Int
}

class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    
    func fetchUsers() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            DispatchQueue.main.async {
                self.users = documents.compactMap { doc in
                    // Exclude the current user
                    if doc.documentID == currentUid {
                        return nil
                    }
                    let data = doc.data()
                    let username = data["username"] as? String ?? "Unknown"
                    let profileImageURL = data["profileImageURL"] as? String ?? ""
                    return User(id: doc.documentID, name: username, profileImageURL: profileImageURL)
                }
            }
        }
    }
}

class GroupsViewModel: ObservableObject {
    @Published var groups: [GroupModel] = []
    
    func fetchGroups() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(uid)
            .collection("groups")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching groups: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.groups = documents.map { doc in
                    let data = doc.data()
                    
                    let groupName = data["groupName"] as? String ?? "Untitled"
                    let groupImageURL = data["groupImageURL"] as? String ?? ""
                    let memberImageURLs = data["members"] as? [String] ?? []
                    
                    return GroupModel(
                        id: doc.documentID,
                        groupName: groupName,
                        groupImageURL: groupImageURL,
                        memberImageURLs: memberImageURLs,
                        memberCount: memberImageURLs.count
                    )
                }
            }
    }
}

struct Home: View {
    @State private var showHalfSheet = false
    @State private var navigateToCamera = false
    @State private var groupRef: DocumentReference? = nil
    
    // ViewModel for fetching and displaying groups
    @StateObject private var groupsViewModel = GroupsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed header at the top
                    Text("Treehouse")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 50)
                        .padding(.leading, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Scrollable group chat cards only
                    ScrollView {
                        VStack(spacing: 50) {
                            ForEach(groupsViewModel.groups) { group in
                                NavigationLink(destination: GroupChat(groupId: group.id)) {
                                    GroupCardView(group: group)
                                }
                            }
                        }
                        .padding(.top, 0)
                        // Extra bottom padding so cards can scroll behind the fixed bottom overlay
                        .padding(.bottom, 120)
                    }
                    // Fill remaining space to ensure the ScrollView reaches the bottom
                    .frame(maxHeight: .infinity)
                }
                .edgesIgnoringSafeArea(.bottom)
                
                // Fixed bottom overlay for buttons
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Image(systemName: "house.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(180))
                            .onTapGesture {
                                showHalfSheet = true
                            }
                        Spacer()
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.001))
                }
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showHalfSheet) {
                HalfSheetView(navigateToCamera: $navigateToCamera, groupRef: $groupRef)
                    .presentationDetents([.medium])
            }
            .background(
                NavigationLink(destination: Camera(groupRef: groupRef)
                                .navigationBarBackButtonHidden(true),
                               isActive: $navigateToCamera) {
                    EmptyView()
                }
            )
            .onAppear {
                groupsViewModel.fetchGroups()
            }
        }
    }
}

struct GroupCardView: View {
    let group: GroupModel

    // Helper view to load images from URL or fallback to asset name
    @ViewBuilder
    private func loadImage(from imageURL: String) -> some View {
        if let url = URL(string: imageURL), imageURL.starts(with: "http") {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                }
            }
        } else {
            Image(imageURL)
                .resizable()
                .scaledToFill()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Avatars, member count, group name
            VStack(spacing: 8) {
                HStack(spacing: -20) {
                    ForEach(Array(group.memberImageURLs.enumerated()), id: \.element) { index, imageURL in
                        loadImage(from: imageURL)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                    }
                }
                .padding(.top, 16)
                
                Text("\(group.memberCount) members")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .offset(y: 5)
                
                Text(group.groupName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            
            Divider()
            
            // Bottom: Sassy caption placeholder
            Text("Sassy captions")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 10)
        )
        .padding(.horizontal, 36)
    }
}


struct GroupCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleGroup = GroupModel(
            id: "sampleId",
            groupName: "Sample Group",
            groupImageURL: "sampleImage",
            memberImageURLs: ["Adam", "Bode", "Hasque", "Abe"],
            memberCount: 4
        )
        return GroupCardView(group: sampleGroup)
            .previewLayout(.sizeThatFits)
    }
}


struct HalfSheetView: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var navigateToCamera: Bool
    @Binding var groupRef: DocumentReference?
    
    @State private var selectedUsers: [String] = []
    @State private var isNamingGroup = false
    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""
    
    // Helper view to load images from URL or asset
    @ViewBuilder
    private func loadImage(from imageURL: String) -> some View {
        if let url = URL(string: imageURL), imageURL.starts(with: "http") {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                }
            }
        } else {
            Image(imageURL)
                .resizable()
                .scaledToFill()
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isNamingGroup {
                GroupNameView(groupName: $groupName,
                              selectedUsers: selectedUsers,
                              onDone: { docRef in
                                  // Save the group document reference, dismiss and navigate
                                  self.groupRef = docRef
                                  dismiss()
                                  navigateToCamera = true
                              })
            } else {
                VStack(spacing: 0) {
                    // Top handle bar
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                    
                    // Horizontal avatars for selected users
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(selectedUsers, id: \.self) { profile in
                                loadImage(from: profile)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                            // Empty placeholders
                            ForEach(0..<(7 - selectedUsers.count), id: \.self) { _ in
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.2),
                                                  style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .frame(width: 40, height: 40)
                            }
                            .offset(x: -3)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                    
                    // List of users from Firebase (excluding the current user)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.users) { user in
                                HStack {
                                    loadImage(from: user.profileImageURL)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                    
                                    Text(user.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedUsers.contains(user.profileImageURL) ? "checkmark.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(selectedUsers.contains(user.profileImageURL) ? .green : .gray.opacity(0.5))
                                        .onTapGesture {
                                            toggleUserSelection(user.profileImageURL)
                                        }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 90)
                    }
                }
                
                // Continue button to switch to group naming view
                Button(action: {
                    isNamingGroup = true
                }) {
                    HStack {
                        Spacer()
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                }
                .frame(width: sizeClass == .compact ? 291 : 400,
                       height: sizeClass == .compact ? 62 : 70)
                .background(colorScheme == .dark ? Color.white : Color.black)
                .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(sizeClass == .compact ? 40 : 50)
                .shadow(radius: 24, x: 0, y: 14)
                .padding(.bottom, 20)
                .contentShape(Rectangle())
                .disabled(selectedUsers.isEmpty)
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
    
    private func toggleUserSelection(_ profileImage: String) {
        if selectedUsers.contains(profileImage) {
            selectedUsers.removeAll { $0 == profileImage }
        } else if selectedUsers.count < 5 {
            selectedUsers.append(profileImage)
        }
    }
}

struct GroupNameView: View {
    @Binding var groupName: String
    let selectedUsers: [String]
    @FocusState private var isKeyboardActive: Bool
    // onDone returns the created DocumentReference (or nil on error)
    var onDone: (DocumentReference?) -> Void
    
    var body: some View {
        VStack {
            // Top handle bar
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            TextField("Name your group chat", text: $groupName)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 10)
                .focused($isKeyboardActive)
                .submitLabel(.done)
                .onSubmit {
                    saveGroupToFirestore { docRef in
                        onDone(docRef)
                    }
                }
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isKeyboardActive = true
            }
        }
    }
    
    private func saveGroupToFirestore(completion: @escaping (DocumentReference?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        let db = Firestore.firestore()
        
        // First, fetch the current user's profile image from Firestore.
        let userDocRef = db.collection("users").document(uid)
        userDocRef.getDocument { document, error in
            var currentUserImage = ""
            if let document = document,
               document.exists,
               let imageUrl = document.data()?["profileImageURL"] as? String {
                currentUserImage = imageUrl
            }
            // Merge the selected users with the current user's profile image.
            var members = selectedUsers
            if !members.contains(currentUserImage) && currentUserImage != "" {
                members.insert(currentUserImage, at: 0)
            }
            // Use the current user's image as the group image.
            let groupData: [String: Any] = [
                "groupName": groupName,
                "members": members,
                "groupImageURL": currentUserImage,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            let newDocRef = db.collection("users")
                .document(uid)
                .collection("groups")
                .document()
            
            newDocRef.setData(groupData) { error in
                if let error = error {
                    print("Error saving group: \(error)")
                    completion(nil)
                } else {
                    print("Group saved successfully.")
                    completion(newDocRef)
                }
            }
        }
    }
}

#Preview {
    Home()
}
