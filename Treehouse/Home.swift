//
//  Home.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct User: Identifiable {
    let id: String
    let name: String
    let profileImageURL: String
}

class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    
    private let userMappings: [(name: String, image: String)] = [
        ("Adam May", "Adam"),
        ("Hasque May", "Hasque"),
        ("Bode Alaka", "Bode"),
        ("Rex May", "Rex"),
        ("Abraham May", "Abe")
    ]
    
    func fetchUsers() {
        users = userMappings.map { user in
            User(id: UUID().uuidString,
                 name: user.name,
                 profileImageURL: user.image) // Using asset names
        }
    }
}

struct Home: View {
    @State private var showHalfSheet = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text("Treehouse")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 50)
                    .padding(.leading, 20)
                
                Text("Create a group chat below")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .offset(y: 260)
                
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
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showHalfSheet) {
            HalfSheetView()
                .presentationDetents([.medium])
                .interactiveDismissDisabled(true) // Prevents dismissal when tapping outside
        }
    }
}

struct HalfSheetView: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedUsers: [String] = []
    @State private var isNamingGroup = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if isNamingGroup {
                GroupNameView()
            } else {
                VStack(spacing: 0) {
                    // Top handle bar
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                    
                    // Horizontal avatars (Dynamic Selection)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Show selected user profile images
                            ForEach(selectedUsers, id: \.self) { profile in
                                Image(profile)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            }
                            // Remaining empty placeholders
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
                    
                    // User list (Scrolls behind the button)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.users) { user in
                                HStack {
                                    Image(user.profileImageURL)
                                        .resizable()
                                        .scaledToFill()
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
                        .padding(.bottom, 90) // Ensures scrolling behind the button
                    }
                }
                
                // Continue button
                Button(action: {
                    isNamingGroup = true // Instantly switch to Group Naming View
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
                .contentShape(Rectangle()) // Ensures the entire area is tappable
                .disabled(selectedUsers.isEmpty) // Keeps button disabled if no users are selected
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
    @State private var groupName = ""
    @FocusState private var isKeyboardActive: Bool

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

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(.keyboard) // Prevents the sheet from moving up when the keyboard appears
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isKeyboardActive = true // Automatically opens the keyboard
            }
        }
    }
}

#Preview {
    Home()
}
