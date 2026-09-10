import FanwrightCore
import SwiftUI

extension ThermalLevel {
    var color: Color {
        switch self {
        case .cool: .green
        case .warm: .yellow
        case .hot: .orange
        case .critical: .red
        }
    }
}
