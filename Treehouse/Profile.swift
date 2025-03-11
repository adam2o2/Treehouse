//
//  Profile.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI

struct Profile: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // State variable to trigger navigation to Username
    @State private var navigateToUsername = false

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
                        // Navigate to Username when tapped
                        navigateToUsername = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Upload a profile picture")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                    .contentShape(Rectangle()) // Makes the entire area tappable
                }
                
                // Hidden NavigationLink that navigates to Username and hides the back button.
                NavigationLink(destination: Username().navigationBarBackButtonHidden(true),
                               isActive: $navigateToUsername) {
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
