import SwiftUI

struct AboutPane: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "computermouse.fill").font(.system(size: 48)).foregroundStyle(.tint)
            Text("XiaomiMouseFix").font(.title2.bold())
            Text("Verzija \(version)").foregroundStyle(.secondary)
            Text("Podešavanja za Xiaomi Silent Mouse 2: programabilna side dugmad, pointer i scroll.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
