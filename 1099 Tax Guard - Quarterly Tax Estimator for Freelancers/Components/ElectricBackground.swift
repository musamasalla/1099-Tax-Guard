//
//  ElectricBackground.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

struct ElectricBackground: View {
    var body: some View {
        ZStack {
            // Base layer
            Theme.electricBlue
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ElectricBackground()
}
