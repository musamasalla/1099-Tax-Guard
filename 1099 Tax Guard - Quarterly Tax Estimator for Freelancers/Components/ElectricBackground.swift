//
//  ElectricBackground.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

struct ElectricBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base layer
            Theme.electricBlue
                .ignoresSafeArea()
            
            // Animated Orb 1 (Cyan)
            Circle()
                .fill(Theme.primaryBlue.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: animate ? -100 : 100, y: animate ? -150 : 50)
                .animation(
                    Animation.easeInOut(duration: 15).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Animated Orb 2 (Deep Blue/Purple)
            Circle()
                .fill(Theme.deepBlue.opacity(0.5))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? 150 : -50, y: animate ? 200 : -100)
                .animation(
                    Animation.easeInOut(duration: 20).repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Animated Orb 3 (Accent Lime - subtle)
            Circle()
                .fill(Theme.neonLime.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: animate ? -50 : 150, y: animate ? 50 : 250)
                .animation(
                    Animation.easeInOut(duration: 12).repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .ignoresSafeArea() // Extend background to all edges
        .drawingGroup() // Optimize performance
        .onAppear {
            animate.toggle()
        }
    }
}

#Preview {
    ElectricBackground()
}
