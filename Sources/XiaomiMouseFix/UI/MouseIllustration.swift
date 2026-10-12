import MouseCore
import SwiftUI

/// Top-down mouse with the two side buttons on its left edge. Clicking a button selects it;
/// a physical press lights it up.
struct MouseIllustration: View {
    @Binding var selected: SideButton
    let pressed: Set<SideButton>

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule(style: .continuous)
                .fill(.quaternary)
                .overlay(Capsule(style: .continuous).stroke(.secondary.opacity(0.5)))
                .overlay(alignment: .top) {
                    Rectangle().fill(.secondary.opacity(0.4)).frame(width: 1, height: 60).padding(.top, 10)
                }
                .frame(width: 110, height: 170)
                .offset(x: 24)
            VStack(spacing: 8) {
                sideButton(.forward)
                sideButton(.back)
            }
            .offset(x: 12, y: 62)
        }
        .frame(width: 140, height: 170)
    }

    private func sideButton(_ button: SideButton) -> some View {
        let isPressed = pressed.contains(button)
        let isSelected = selected == button
        return Button {
            selected = button
        } label: {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(isPressed ? Color.accentColor : Color.secondary.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2))
                .frame(width: 20, height: 32)
        }
        .buttonStyle(.plain)
        .help(button.title)
        .accessibilityLabel(button.title)
    }
}
