//
//  AnimatableNumber.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

struct AnimatableNumber: View {
    let value: Double
    let format: (Double) -> String
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(format(displayValue))
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                displayValue = 0
                withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}
