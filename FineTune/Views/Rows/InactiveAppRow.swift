// FineTune/Views/Rows/InactiveAppRow.swift
import SwiftUI

/// A row displaying a pinned but inactive app (not currently producing audio).
/// Similar to AppRow but:
/// - Uses PinnedAppInfo instead of AudioApp
/// - VU meter always shows 0 (no audio level polling)
/// - Slightly dimmed appearance to indicate inactive state
/// - All settings (volume/mute/EQ/device) work normally and are persisted
struct InactiveAppRow: View {
    let appInfo: PinnedAppInfo
    let icon: NSImage
    let volume: Float  // Linear gain 0-maxVolumeBoost
    let devices: [AudioDevice]
    let selectedDeviceUID: String?
    let selectedDeviceUIDs: Set<String>
    let isFollowingDefault: Bool
    let defaultDeviceUID: String?
    let deviceSelectionMode: DeviceSelectionMode
    let isMuted: Bool
    let maxVolumeBoost: Float
    let onVolumeChange: (Float) -> Void
    let onMuteChange: (Bool) -> Void
    let onDeviceSelected: (String) -> Void
    let onDevicesSelected: (Set<String>) -> Void
    let onDeviceModeChange: (DeviceSelectionMode) -> Void
    let onSelectFollowDefault: () -> Void
    let onUnpin: () -> Void  // Inactive apps can only be unpinned
    let eqSettings: EQSettings
    let onEQChange: (EQSettings) -> Void
    let isEQExpanded: Bool
    let onEQToggle: () -> Void

    @State private var dragOverrideValue: Double?
    @State private var isEQButtonHovered = false
    @State private var isPinButtonHovered = false
    @State private var localEQSettings: EQSettings

    /// Slider value - computed from volume/maxBoost, or drag override while dragging
    private var sliderValue: Double {
        dragOverrideValue ?? VolumeMapping.gainToSlider(volume, maxBoost: maxVolumeBoost)
    }

    /// Show muted icon when explicitly muted OR volume is 0
    private var showMutedIcon: Bool { isMuted || sliderValue == 0 }

    /// EQ button color following same pattern as MuteButton
    private var eqButtonColor: Color {
        if isEQExpanded {
            return DesignTokens.Colors.interactiveActive
        } else if isEQButtonHovered {
            return DesignTokens.Colors.interactiveHover
        } else {
            return DesignTokens.Colors.interactiveDefault
        }
    }

    /// Pin button color - always visible for inactive (pinned) apps
    private var pinButtonColor: Color {
        if isPinButtonHovered {
            return DesignTokens.Colors.interactiveHover
        } else {
            return DesignTokens.Colors.interactiveActive  // Always active (pinned)
        }
    }

    init(
        appInfo: PinnedAppInfo,
        icon: NSImage,
        volume: Float,
        devices: [AudioDevice],
        selectedDeviceUID: String?,
        selectedDeviceUIDs: Set<String> = [],
        isFollowingDefault: Bool = true,
        defaultDeviceUID: String? = nil,
        deviceSelectionMode: DeviceSelectionMode = .single,
        isMuted: Bool = false,
        maxVolumeBoost: Float = 2.0,
        onVolumeChange: @escaping (Float) -> Void,
        onMuteChange: @escaping (Bool) -> Void,
        onDeviceSelected: @escaping (String) -> Void,
        onDevicesSelected: @escaping (Set<String>) -> Void = { _ in },
        onDeviceModeChange: @escaping (DeviceSelectionMode) -> Void = { _ in },
        onSelectFollowDefault: @escaping () -> Void = {},
        onUnpin: @escaping () -> Void,
        eqSettings: EQSettings = EQSettings(),
        onEQChange: @escaping (EQSettings) -> Void = { _ in },
        isEQExpanded: Bool = false,
        onEQToggle: @escaping () -> Void = {}
    ) {
        self.appInfo = appInfo
        self.icon = icon
        self.volume = volume
        self.devices = devices
        self.selectedDeviceUID = selectedDeviceUID
        self.selectedDeviceUIDs = selectedDeviceUIDs
        self.isFollowingDefault = isFollowingDefault
        self.defaultDeviceUID = defaultDeviceUID
        self.deviceSelectionMode = deviceSelectionMode
        self.isMuted = isMuted
        self.maxVolumeBoost = maxVolumeBoost
        self.onVolumeChange = onVolumeChange
        self.onMuteChange = onMuteChange
        self.onDeviceSelected = onDeviceSelected
        self.onDevicesSelected = onDevicesSelected
        self.onDeviceModeChange = onDeviceModeChange
        self.onSelectFollowDefault = onSelectFollowDefault
        self.onUnpin = onUnpin
        self.eqSettings = eqSettings
        self.onEQChange = onEQChange
        self.isEQExpanded = isEQExpanded
        self.onEQToggle = onEQToggle
        self._localEQSettings = State(initialValue: eqSettings)
    }

    var body: some View {
        ExpandableGlassRow(isExpanded: isEQExpanded) {
            // Header: Main row content (always visible)
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Unpin star button - left of app icon
                Button {
                    onUnpin()
                } label: {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(pinButtonColor)
                        .frame(
                            minWidth: DesignTokens.Dimensions.minTouchTarget,
                            minHeight: DesignTokens.Dimensions.minTouchTarget
                        )
                        .contentShape(Rectangle())
                        .scaleEffect(isPinButtonHovered ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { isPinButtonHovered = $0 }
                .help("Unpin app")
                .animation(DesignTokens.Animation.hover, value: pinButtonColor)
                .animation(DesignTokens.Animation.quick, value: isPinButtonHovered)

                // App icon (no activation for inactive apps - can't bring to front what isn't running)
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: DesignTokens.Dimensions.iconSize, height: DesignTokens.Dimensions.iconSize)
                    .opacity(0.6)  // Dimmed to indicate inactive state

                // App name - expands to fill available space
                Text(appInfo.displayName)
                    .font(DesignTokens.Typography.rowName)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)  // Dimmed text

                // Controls section - fixed width so sliders align across rows
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // Mute button
                    MuteButton(isMuted: showMutedIcon) {
                        if showMutedIcon {
                            // Unmute: restore to default volume if at 0
                            if volume == 0 {
                                onVolumeChange(1.0)
                            }
                            onMuteChange(false)
                        } else {
                            onMuteChange(true)
                        }
                    }

                    // Volume slider with unity marker
                    LiquidGlassSlider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                dragOverrideValue = newValue
                                let gain = VolumeMapping.sliderToGain(newValue, maxBoost: maxVolumeBoost)
                                onVolumeChange(gain)
                                if isMuted {
                                    onMuteChange(false)
                                }
                            }
                        ),
                        showUnityMarker: true,
                        onEditingChanged: { editing in
                            if !editing {
                                dragOverrideValue = nil
                            }
                        }
                    )
                    .frame(width: DesignTokens.Dimensions.sliderWidth)
                    .opacity(showMutedIcon ? 0.5 : 1.0)

                    // Editable volume percentage
                    EditablePercentage(
                        percentage: Binding(
                            get: {
                                let gain = VolumeMapping.sliderToGain(sliderValue, maxBoost: maxVolumeBoost)
                                return Int(round(gain * 100))
                            },
                            set: { newPercentage in
                                let gain = Float(newPercentage) / 100.0
                                onVolumeChange(gain)
                            }
                        ),
                        range: 0...Int(round(maxVolumeBoost * 100))
                    )

                    // VU Meter - always shows 0 for inactive apps
                    VUMeter(level: 0, isMuted: showMutedIcon)

                    // Device picker
                    DevicePicker(
                        devices: devices,
                        selectedDeviceUID: selectedDeviceUID ?? defaultDeviceUID ?? "",
                        selectedDeviceUIDs: selectedDeviceUIDs,
                        isFollowingDefault: isFollowingDefault,
                        defaultDeviceUID: defaultDeviceUID,
                        mode: deviceSelectionMode,
                        onModeChange: onDeviceModeChange,
                        onDeviceSelected: onDeviceSelected,
                        onDevicesSelected: onDevicesSelected,
                        onSelectFollowDefault: onSelectFollowDefault,
                        showModeToggle: true
                    )

                    // EQ button
                    Button {
                        onEQToggle()
                    } label: {
                        ZStack {
                            Image(systemName: "slider.vertical.3")
                                .opacity(isEQExpanded ? 0 : 1)
                                .rotationEffect(.degrees(isEQExpanded ? 90 : 0))

                            Image(systemName: "xmark")
                                .opacity(isEQExpanded ? 1 : 0)
                                .rotationEffect(.degrees(isEQExpanded ? 0 : -90))
                        }
                        .font(.system(size: 12))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(eqButtonColor)
                        .frame(
                            minWidth: DesignTokens.Dimensions.minTouchTarget,
                            minHeight: DesignTokens.Dimensions.minTouchTarget
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { isEQButtonHovered = $0 }
                    .help(isEQExpanded ? "Close Equalizer" : "Equalizer")
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isEQExpanded)
                    .animation(DesignTokens.Animation.hover, value: isEQButtonHovered)
                }
                .frame(width: DesignTokens.Dimensions.controlsWidth)
            }
            .frame(height: DesignTokens.Dimensions.rowContentHeight)
        } expandedContent: {
            // EQ panel
            EQPanelView(
                settings: $localEQSettings,
                onPresetSelected: { preset in
                    localEQSettings = preset.settings
                    onEQChange(preset.settings)
                },
                onSettingsChanged: { settings in
                    onEQChange(settings)
                }
            )
            .padding(.top, DesignTokens.Spacing.sm)
        }
        .onChange(of: eqSettings) { _, newValue in
            localEQSettings = newValue
        }
    }
}
