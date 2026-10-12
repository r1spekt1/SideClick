import AppKit
import SwiftUI

struct AboutPane: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text("XiaomiMouseFix").font(.title2.bold())
            Text("Verzija \(version)").foregroundStyle(.secondary)
            Text("Podešavanja za Xiaomi Silent Mouse 2: programabilna side dugmad, pointer i scroll.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
