//
//  Profile.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI

struct Profile: View {
    // Match the adaptive styling used in other files
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // State variable to trigger navigation to Home
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 40)
                    
                    // Title
                    Text("Upload a profile photo")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .offset(y: -150)
                    
                    // Circle with a person icon
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // "Upload a profile picture" button
                    Button(action: {
                        // Navigate to Home when tapped
                        navigateToHome = true
                    }) {
                        Text("Upload a profile picture")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .frame(width: sizeClass == .compact ? 291 : 400,
                           height: sizeClass == .compact ? 62 : 70)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(sizeClass == .compact ? 40 : 50)
                    .shadow(radius: 24, x: 0, y: 14)
                    .padding(.bottom, sizeClass == .compact ? 20 : 30)
                }
                
                // Hidden NavigationLink to navigate to Home and hide the back button.
                NavigationLink(destination: Home().navigationBarBackButtonHidden(true),
                               isActive: $navigateToHome) {
                    EmptyView()
                }
                               .hidden()
            }
        }
    }
}

#Preview {
    Profile()
}
