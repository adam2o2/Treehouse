//
//  Username.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Username: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // Local state to store the username text
    @State private var username: String = ""
    // State variable to trigger navigation to Home
    @State private var navigateToHome = false
    // State variable to show a loading indicator while saving
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    // Title and subtitle
                    VStack {
                        Text("Create a username")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        Text("Under 15 characters pls!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            .offset(y: 5)
                    }
                    .offset(y: 60)
                    
                    // Text field for username
                    TextField("adam", text: $username)
                        .padding()
                        .frame(width: 300, height: 70)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .offset(y: 300)
                    
                    Spacer()
                    
                    // "Continue" button styled like the Apple sign-in button
                    Button(action: {
                        saveUsername()
                    }) {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                    .contentShape(Rectangle()) // Ensures the entire area is tappable
                    .disabled(username.isEmpty || isSaving)
                }
                
                // Hidden NavigationLink that navigates to Home and hides the back button.
                NavigationLink(destination: Home().navigationBarBackButtonHidden(true),
                               isActive: $navigateToHome) {
                    EmptyView()
                }
                .hidden()
            }
            // Prevent the keyboard from shifting the layout for the bottom edge.
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    // This function saves the username to Firestore under the current user's UID.
    func saveUsername() {
        guard !username.isEmpty else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        isSaving = true
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData(["username": username], merge: true) { error in
            isSaving = false
            if let error = error {
                print("Error saving username: \(error.localizedDescription)")
            } else {
                // Navigate to Home view after successful save
                navigateToHome = true
            }
        }
    }
}

#Preview {
    Username()
}
