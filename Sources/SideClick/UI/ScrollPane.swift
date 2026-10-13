import SwiftUI

struct ScrollPane: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Direction and step") {
                Toggle("Reverse scroll direction", isOn: $model.settings.scroll.inverted)
                LabeledContent("Step") {
                    HStack {
                        Slider(value: $model.settings.scroll.lineMultiplier, in: 0.25...5)
                        Text(String(format: "%.2g×", model.settings.scroll.lineMultiplier))
                            .monospacedDigit().frame(width: 44, alignment: .trailing)
                    }
                }
                Toggle("Shift scrolls horizontally", isOn: $model.settings.scroll.shiftScrollsHorizontally)
            }
            Section("Smooth scrolling") {
                Toggle("Enable smooth scrolling", isOn: $model.settings.scroll.smoothEnabled)
                Group {
                    LabeledContent("Speed") {
                        Slider(value: $model.settings.scroll.smoothPixelsPerLine, in: 20...200)
                    }
                    LabeledContent("Duration") {
                        HStack {
                            Slider(value: $model.settings.scroll.smoothDuration, in: 0.1...0.6)
                            Text("\(Int(model.settings.scroll.smoothDuration * 1000)) ms")
                                .monospacedDigit().frame(width: 56, alignment: .trailing)
                        }
                    }
                }
                .disabled(!model.settings.scroll.smoothEnabled)
            }
        }
        .formStyle(.grouped)
    }
}
