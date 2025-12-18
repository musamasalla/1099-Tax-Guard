//
//  CapsuleTabBar.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

struct CapsuleTabBar: View {
    @Binding var selectedTab: Int
    
    // Tab Items - Updated to include Payments
    let items: [(image: String, title: String)] = [
        ("house.fill", "Home"),
        ("dollarsign.circle.fill", "Income"),
        ("list.bullet.rectangle.portrait.fill", "Deductions"),
        ("creditcard.fill", "Payments"),
        ("gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: items[index].image)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(selectedTab == index ? Theme.textDark : Theme.pureWhite.opacity(0.6))
                        
                        if selectedTab == index {
                            Text(items[index].title)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textDark)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(Theme.neonLime)
                                    .matchedGeometryEffect(id: "TabBackground", in: namespace)
                            }
                        }
                    )
                }
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8)) // Dark capsule background
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 16) // Bottom padding for safe area
    }
    
    @Namespace private var namespace
}

#Preview {
    ZStack {
        Theme.electricBlue.ignoresSafeArea()
        VStack {
            Spacer()
            CapsuleTabBar(selectedTab: .constant(0))
        }
    }
}
