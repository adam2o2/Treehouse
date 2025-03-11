//
//  Home.swift
//  Treehouse
//
//  Created by Safiya May on 3/11/25.
//

import SwiftUI

struct Home: View {
    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                // Large title at the top-left
                Text("Treehouse")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 50)       // Adjust top padding as needed
                    .padding(.leading, 20)   // Left padding
                
                
                // Centered subtitle text
                Text("Create a group chat below")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .offset(y: 260)
                
                Spacer()
                
                // Bottom tab bar with three icons
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

                    Spacer()
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.bottom, 20) // Adjust bottom spacing as needed
            }
        }
    }
}

#Preview {
    Home()
}
