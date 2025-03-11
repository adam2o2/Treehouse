//
//  ContentView.swift
//  Treehouse
//
//  Created by Safiya May on 3/10/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 40)
                
                // Title
                Text("Take a daily photo")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                
                // "Phone" shape with the Bode image and gradient at the bottom
                ZStack {
                    // White rounded rectangle behind the image
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 300, height: 450)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                    
                    // Bode image with white stroke and bottom gradient overlay
                    Image("Bode")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        // Overlay a gradient at the bottom of the image
                        .overlay(
                            VStack {
                                Spacer()
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 100) // Adjust height as needed
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                        )
                        
                    // Circle near the bottom to mimic a shutter button
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .background(Circle().fill(Color.white))
                        .frame(width: 50, height: 50)
                        .offset(y: 170)
                }
                .padding(.vertical, 20)
                .offset(y: 30)
                
                Spacer()
                
                // "Continue" button styled like the Apple sign-in button
                Button(action: {
                    // Handle your "Continue" action here
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
    ContentView()
}
