//
//  SignUp.swift
//  Treehouse
//
//  Created by Safiya May on 3/10/25.
//

import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

struct SignUp: View {
    @State private var imagesAppeared = false
    @State private var currentNonce: String?
    @State private var isUserAuthenticated = false

    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                Text("Treehouse")
                    .font(.system(size: 39, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("only one photo a day.")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .offset(y: 10)
                
                HStack {
                    Spacer()
                    HStack {
                        Image("Abe")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: sizeClass == .regular ? 150 : 116,
                                   height: sizeClass == .regular ? 220 : 169.35)
                            .clipped()
                            .cornerRadius(19)
                            .overlay(
                                RoundedRectangle(cornerRadius: 19)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .rotationEffect(Angle(degrees: -16))
                            .offset(x: 25, y: 15)
                            .shadow(radius: 24, x: 0, y: 14)
                            .zIndex(3)
                            .scaleEffect(imagesAppeared ? 1 : 0)
                            .animation(.interpolatingSpring(stiffness: 60, damping: 6)
                                .delay(0.1), value: imagesAppeared)
                            .onAppear {
                                if imagesAppeared {
                                    triggerHaptic()
                                }
                            }

                        Image("Adam")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: sizeClass == .regular ? 150 : 116,
                                   height: sizeClass == .regular ? 220 : 169.35)
                            .clipped()
                            .cornerRadius(19)
                            .overlay(
                                RoundedRectangle(cornerRadius: 19)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .zIndex(2)
                            .rotationEffect(Angle(degrees: -2))
                            .shadow(radius: 24, x: 0, y: 14)
                            .scaleEffect(imagesAppeared ? 1 : 0)
                            .animation(.interpolatingSpring(stiffness: 60, damping: 6)
                                .delay(0.2), value: imagesAppeared)
                            .onAppear {
                                if imagesAppeared {
                                    triggerHaptic()
                                }
                            }

                        Image("Bode")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: sizeClass == .regular ? 150 : 116,
                                   height: sizeClass == .regular ? 220 : 169.35)
                            .clipped()
                            .cornerRadius(19)
                            .overlay(
                                RoundedRectangle(cornerRadius: 19)
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .zIndex(1)
                            .rotationEffect(Angle(degrees: 17))
                            .shadow(radius: 24, x: 0, y: 14)
                            .offset(x: -33, y: 15)
                            .scaleEffect(imagesAppeared ? 1 : 0)
                            .animation(.interpolatingSpring(stiffness: 60, damping: 6)
                                .delay(0.3), value: imagesAppeared)
                            .onAppear {
                                if imagesAppeared {
                                    triggerHaptic()
                                }
                            }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, sizeClass == .compact ? 118 : 290)
                    Spacer()
                }
                
                // Hidden NavigationLink for redirection after successful sign in,
                // with the back button hidden on ContentView.
                NavigationLink(destination: ContentView().navigationBarBackButtonHidden(true), isActive: $isUserAuthenticated) {
                    EmptyView()
                }
                
                // Sign in with Apple button with Firebase integration
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                                print("Error retrieving AppleID Credential")
                                return
                            }
                            guard let nonce = currentNonce else {
                                print("Invalid state: No login request sent.")
                                return
                            }
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                print("Unable to fetch identity token")
                                return
                            }
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                                return
                            }
                            
                            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                                      idToken: idTokenString,
                                                                      rawNonce: nonce)
                            
                            Auth.auth().signIn(with: credential) { authResult, error in
                                if let error = error {
                                    print("Firebase sign in error: \(error.localizedDescription)")
                                    return
                                }
                                
                                guard let user = authResult?.user else {
                                    print("No user found in authResult")
                                    return
                                }
                                
                                // Store user info in Firestore
                                let db = Firestore.firestore()
                                db.collection("users").document(user.uid).setData([
                                    "email": user.email ?? "",
                                    "uid": user.uid
                                ]) { error in
                                    if let error = error {
                                        print("Error writing document: \(error.localizedDescription)")
                                    } else {
                                        print("User data successfully written!")
                                        // Redirect to ContentView
                                        DispatchQueue.main.async {
                                            isUserAuthenticated = true
                                            print("isUserAuthenticated set to true")
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(width: sizeClass == .compact ? 291 : 400,
                       height: sizeClass == .compact ? 62 : 70)
                .cornerRadius(sizeClass == .compact ? 40 : 50)
                .shadow(radius: 24, x: 0, y: 14)
                .padding(.bottom, sizeClass == .compact ? 20 : 30)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 134)
            .onAppear {
                imagesAppeared = true
                triggerHaptic()
            }
            .onDisappear {
                imagesAppeared = false
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    // Helper functions for nonce generation and hashing
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    SignUp()
}
