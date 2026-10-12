import SwiftUI

struct ConflictWarning: View {
    let names: [String]

    var body: some View {
        Label {
            Text("\(names.joined(separator: ", ")) presreće dodatna dugmad miša. Isključi njegove mouse funkcije da bi side dugmad radila ovde.")
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
    }
}
