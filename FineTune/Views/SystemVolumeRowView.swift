// FineTune/Views/SystemVolumeRowView.swift
import SwiftUI

struct SystemVolumeRowView: View {
    let deviceName: String
    let deviceIcon: NSImage?
    let volume: Float  // 0-1
    let onVolumeChange: (Float) -> Void

    @State private var sliderValue: Double  // 0-1

    init(
        deviceName: String,
        deviceIcon: NSImage?,
        volume: Float,
        onVolumeChange: @escaping (Float) -> Void
    ) {
        self.deviceName = deviceName
        self.deviceIcon = deviceIcon
        self.volume = volume
        self.onVolumeChange = onVolumeChange
        self._sliderValue = State(initialValue: Double(volume))
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let icon = deviceIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "speaker.wave.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 24, height: 24)

            Text(deviceName)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)

            Slider(value: $sliderValue, in: 0...1)
                .frame(minWidth: 80)
                .onChange(of: sliderValue) { _, newValue in
                    onVolumeChange(Float(newValue))
                }

            Text("\(Int(sliderValue * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .onChange(of: volume) { _, newValue in
            sliderValue = Double(newValue)
        }
    }
}
