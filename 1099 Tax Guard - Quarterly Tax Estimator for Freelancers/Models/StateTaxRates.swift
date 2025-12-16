//
//  StateTaxRates.swift
//  1099 Tax Guard
//
//  Created by Musa Masalla on 2025/12/16.
//

import Foundation

// MARK: - US State
enum USState: String, CaseIterable, Codable {
    case alabama = "AL"
    case alaska = "AK"
    case arizona = "AZ"
    case arkansas = "AR"
    case california = "CA"
    case colorado = "CO"
    case connecticut = "CT"
    case delaware = "DE"
    case florida = "FL"
    case georgia = "GA"
    case hawaii = "HI"
    case idaho = "ID"
    case illinois = "IL"
    case indiana = "IN"
    case iowa = "IA"
    case kansas = "KS"
    case kentucky = "KY"
    case louisiana = "LA"
    case maine = "ME"
    case maryland = "MD"
    case massachusetts = "MA"
    case michigan = "MI"
    case minnesota = "MN"
    case mississippi = "MS"
    case missouri = "MO"
    case montana = "MT"
    case nebraska = "NE"
    case nevada = "NV"
    case newHampshire = "NH"
    case newJersey = "NJ"
    case newMexico = "NM"
    case newYork = "NY"
    case northCarolina = "NC"
    case northDakota = "ND"
    case ohio = "OH"
    case oklahoma = "OK"
    case oregon = "OR"
    case pennsylvania = "PA"
    case rhodeIsland = "RI"
    case southCarolina = "SC"
    case southDakota = "SD"
    case tennessee = "TN"
    case texas = "TX"
    case utah = "UT"
    case vermont = "VT"
    case virginia = "VA"
    case washington = "WA"
    case westVirginia = "WV"
    case wisconsin = "WI"
    case wyoming = "WY"
    case districtOfColumbia = "DC"
    
    var fullName: String {
        switch self {
        case .alabama: return "Alabama"
        case .alaska: return "Alaska"
        case .arizona: return "Arizona"
        case .arkansas: return "Arkansas"
        case .california: return "California"
        case .colorado: return "Colorado"
        case .connecticut: return "Connecticut"
        case .delaware: return "Delaware"
        case .florida: return "Florida"
        case .georgia: return "Georgia"
        case .hawaii: return "Hawaii"
        case .idaho: return "Idaho"
        case .illinois: return "Illinois"
        case .indiana: return "Indiana"
        case .iowa: return "Iowa"
        case .kansas: return "Kansas"
        case .kentucky: return "Kentucky"
        case .louisiana: return "Louisiana"
        case .maine: return "Maine"
        case .maryland: return "Maryland"
        case .massachusetts: return "Massachusetts"
        case .michigan: return "Michigan"
        case .minnesota: return "Minnesota"
        case .mississippi: return "Mississippi"
        case .missouri: return "Missouri"
        case .montana: return "Montana"
        case .nebraska: return "Nebraska"
        case .nevada: return "Nevada"
        case .newHampshire: return "New Hampshire"
        case .newJersey: return "New Jersey"
        case .newMexico: return "New Mexico"
        case .newYork: return "New York"
        case .northCarolina: return "North Carolina"
        case .northDakota: return "North Dakota"
        case .ohio: return "Ohio"
        case .oklahoma: return "Oklahoma"
        case .oregon: return "Oregon"
        case .pennsylvania: return "Pennsylvania"
        case .rhodeIsland: return "Rhode Island"
        case .southCarolina: return "South Carolina"
        case .southDakota: return "South Dakota"
        case .tennessee: return "Tennessee"
        case .texas: return "Texas"
        case .utah: return "Utah"
        case .vermont: return "Vermont"
        case .virginia: return "Virginia"
        case .washington: return "Washington"
        case .westVirginia: return "West Virginia"
        case .wisconsin: return "Wisconsin"
        case .wyoming: return "Wyoming"
        case .districtOfColumbia: return "Washington D.C."
        }
    }
    
    var hasNoIncomeTax: Bool {
        switch self {
        case .alaska, .florida, .nevada, .southDakota, .texas, .washington, .wyoming:
            return true
        case .newHampshire, .tennessee:
            // These states only tax interest and dividends, not earned income
            return true
        default:
            return false
        }
    }
    
    // 2025 State Tax Rates (simplified - using top marginal rate for estimation)
    // In production, this would use full bracket calculations
    var taxRate: Double {
        switch self {
        case .alaska, .florida, .nevada, .southDakota, .texas, .washington, .wyoming:
            return 0.0
        case .newHampshire, .tennessee:
            return 0.0 // No tax on earned income
        case .alabama:
            return 0.05
        case .arizona:
            return 0.025 // Flat rate as of 2023
        case .arkansas:
            return 0.044
        case .california:
            return 0.1330 // Top rate
        case .colorado:
            return 0.044 // Flat rate
        case .connecticut:
            return 0.0699
        case .delaware:
            return 0.066
        case .georgia:
            return 0.0549
        case .hawaii:
            return 0.11
        case .idaho:
            return 0.058
        case .illinois:
            return 0.0495 // Flat rate
        case .indiana:
            return 0.0305 // Flat rate
        case .iowa:
            return 0.057
        case .kansas:
            return 0.057
        case .kentucky:
            return 0.04 // Flat rate
        case .louisiana:
            return 0.0425
        case .maine:
            return 0.0715
        case .maryland:
            return 0.0575
        case .massachusetts:
            return 0.05 // Flat rate + 4% surcharge on income over $1M
        case .michigan:
            return 0.0425 // Flat rate
        case .minnesota:
            return 0.0985
        case .mississippi:
            return 0.05
        case .missouri:
            return 0.048
        case .montana:
            return 0.0675
        case .nebraska:
            return 0.0664
        case .newJersey:
            return 0.1075
        case .newMexico:
            return 0.059
        case .newYork:
            return 0.109 // Top rate (NYC adds local tax)
        case .northCarolina:
            return 0.0475 // Flat rate
        case .northDakota:
            return 0.029
        case .ohio:
            return 0.0399
        case .oklahoma:
            return 0.0475
        case .oregon:
            return 0.099
        case .pennsylvania:
            return 0.0307 // Flat rate
        case .rhodeIsland:
            return 0.0599
        case .southCarolina:
            return 0.064
        case .utah:
            return 0.0465 // Flat rate
        case .vermont:
            return 0.0875
        case .virginia:
            return 0.0575
        case .westVirginia:
            return 0.0512
        case .wisconsin:
            return 0.0765
        case .districtOfColumbia:
            return 0.1075
        }
    }
    
    // Calculate state tax based on taxable income
    func calculateTax(on taxableIncome: Double) -> Double {
        // Simplified calculation using flat rate
        // In production, would use full bracket calculations per state
        return taxableIncome * taxRate
    }
}

// MARK: - State Tax Info Display
extension USState {
    var taxDescription: String {
        if hasNoIncomeTax {
            return "No state income tax"
        } else {
            let percentage = String(format: "%.1f", taxRate * 100)
            return "Up to \(percentage)% state income tax"
        }
    }
}
