import SwiftUI

struct OverviewView: View {
    static let trendsExpandedKey = "showOverviewTrends"

    @Environment(AppModel.self) private var model

    var body: some View {
        if case .unavailable(let message) = model.monitor.availability {
            ContentUnavailableView("Sensors Unavailable", systemImage: "thermometer.medium.slash", description: Text(message))
        } else {
            HStack(alignment: .top, spacing: 16) {
                ThermalCard()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                FansCard()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(24)
        }
    }
}
