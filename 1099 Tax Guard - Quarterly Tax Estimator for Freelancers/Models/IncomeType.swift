//
//  IncomeType.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation

enum IncomeType: String, CaseIterable, Codable {
    case nec = "1099-NEC"
    case k = "1099-K"
    case misc = "1099-MISC"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .nec:
            return "Non-Employee Compensation (freelance work)"
        case .k:
            return "Payment Card & Third Party Network (Uber, Airbnb, etc.)"
        case .misc:
            return "Miscellaneous Income (rent, royalties, prizes)"
        }
    }
    
    var icon: String {
        switch self {
        case .nec:
            return "person.fill"
        case .k:
            return "creditcard.fill"
        case .misc:
            return "doc.text.fill"
        }
    }
}
