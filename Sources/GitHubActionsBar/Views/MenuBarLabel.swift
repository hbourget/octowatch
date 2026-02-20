import SwiftUI

struct MenuBarLabel: View {
    let status: AggregateStatus

    var body: some View {
        Image(systemName: status.iconName)
            .symbolRenderingMode(.hierarchical)
    }
}
