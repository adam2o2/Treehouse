//
//  Username.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI

struct Username: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // Local state to store the username text
    @State private var username: String = ""

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            VStack {
                // Title
                VStack {
                    Text("Create a username")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    
                    // Subtitle
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
                
                // Continue button styled like the Apple sign-in button
                Button(action: {
                    // Handle "Continue" action here
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .frame(width: sizeClass == .compact ? 291 : 400,
                       height: sizeClass == .compact ? 62 : 70)
                .background(colorScheme == .dark ? Color.white : Color.black)
                .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(sizeClass == .compact ? 40 : 50)
                .shadow(radius: 24, x: 0, y: 14)
                .padding(.bottom, sizeClass == .compact ? 20 : 30)
            }
        }
    }
}

#Preview {
    Username()
}
