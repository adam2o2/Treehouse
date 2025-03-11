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
    
    // This state variable controls whether the text overlay (and shutter circle) changes
    @State private var showOverlay = false
    
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
                            // White stroke around the image
                            RoundedRectangle(cornerRadius: 44, style: .continuous)
                                .stroke(Color.white, lineWidth: 4)
                        )
                        // Overlay a gradient at the bottom of the image
                        .overlay(
                            // Linear gradient at the bottom
                            VStack {
                                Spacer()
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 100)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                        )
                        .overlay(
                            // Overlay for "Bode", "10m", and bottom caption once showOverlay == true
                            Group {
                                if showOverlay {
                                    VStack {
                                        // Top bar with "Bode" on the left and "10m" on the right
                                        HStack {
                                            Text("Bode")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.4))
                                                .clipShape(Capsule())
                                            
                                            Spacer()
                                            
                                            Text("10m")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.top, 16)
                                        .padding(.horizontal, 16)
                                        
                                        Spacer()
                                        
                                        // Bottom caption
                                        Text("bro thinks he can surf.")
                                            .font(.system(size: 21, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 24)
                                            .offset(y: -10)
                                    }
                                    .transition(.opacity)  // Fade in/out
                                    .animation(.easeInOut, value: showOverlay)
                                }
                            }
                        )
                    
                    // White circle (shutter button) shown only if showOverlay == false
                    if !showOverlay {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .background(Circle().fill(Color.white))
                            .frame(width: 50, height: 50)
                            .offset(y: 170)
                    }
                }
                .padding(.vertical, 20)
                .offset(y: 30)
                
                Spacer()
                
                // "Continue" button styled like the Apple sign-in button
                Button(action: {
                    // When tapped, remove the shutter circle and show text overlays
                    showOverlay = true
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
