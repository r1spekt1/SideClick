import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("XiaomiMouseFix").font(.headline)
            if model.isAccessibilityGranted {
                Text("Accessibility: odobreno").font(.caption).foregroundStyle(.secondary)
            } else {
                Button("Odobri Accessibility pristup…") { model.requestAccessibility() }
            }
            Divider()
            Button("Izađi") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
    }
}
