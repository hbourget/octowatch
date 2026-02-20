import SwiftUI

struct FooterView: View {
    let username: String
    let onSignOut: () -> Void

    var body: some View {
        HStack {
            Label(username, systemImage: "person.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button("Sign Out") {
                onSignOut()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("·")
                .foregroundStyle(.quaternary)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
