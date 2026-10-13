import SwiftUI

struct ConflictWarning: View {
    let names: [String]

    var body: some View {
        Label {
            Text("\(names.joined(separator: ", ")) is intercepting the extra mouse buttons. Turn off its mouse features so the side buttons work here.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
    }
}
