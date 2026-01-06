// FineTune/Views/DeviceVolumeRowView.swift
import SwiftUI

struct DeviceVolumeRowView: View {
    let device: AudioDevice
    let volume: Float  // 0-1
    let isDefault: Bool
    let onVolumeChange: (Float) -> Void
    let onSetAsDefault: () -> Void

    @State private var sliderValue: Double  // 0-1

    init(
        device: AudioDevice,
        volume: Float,
        isDefault: Bool,
        onVolumeChange: @escaping (Float) -> Void,
        onSetAsDefault: @escaping () -> Void
    ) {
        self.device = device
        self.volume = volume
        self.isDefault = isDefault
        self.onVolumeChange = onVolumeChange
        self.onSetAsDefault = onSetAsDefault
        self._sliderValue = State(initialValue: Double(volume))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Clickable radio button for default selection
            Button {
                if !isDefault {
                    onSetAsDefault()
                }
            } label: {
                Image(systemName: isDefault ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDefault ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .help(isDefault ? "Current default output" : "Set as default output device")

            // Icon - use device.icon with SF Symbol fallback
            if let icon = device.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "speaker.wave.2")
                    .frame(width: 24, height: 24)
            }

            // Name - bolder if default
            Text(device.name)
                .fontWeight(isDefault ? .semibold : .regular)
                .lineLimit(1)

            // Slider
            Slider(value: $sliderValue, in: 0...1)
                .frame(minWidth: 120)
                .tint(.white.opacity(0.7))
                .onChange(of: sliderValue) { _, newValue in
                    onVolumeChange(Float(newValue))
                }

            // Percentage
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
