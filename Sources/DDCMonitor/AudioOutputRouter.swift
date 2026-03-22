import CoreAudio

/// Checks whether the current default audio output is an external display
/// (HDMI / DisplayPort / Thunderbolt), meaning DDC volume control should apply.
enum AudioOutputRouter {

    /// Returns true when the default audio output is routed through an external display.
    static func isOutputOnExternalDisplay() -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }
        let transport = transportType(for: deviceID)
        let isExternal = [
            kAudioDeviceTransportTypeHDMI,
            kAudioDeviceTransportTypeDisplayPort,
            kAudioDeviceTransportTypeThunderbolt,
        ].contains(transport)
        AppLog.log("[Audio] output transport=0x\(String(transport, radix: 16)) isExternal=\(isExternal)")
        return isExternal
    }

    // MARK: - Private

    private static func defaultOutputDeviceID() -> AudioObjectID? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private static func transportType(for deviceID: AudioObjectID) -> UInt32 {
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)
        return transport
    }
}
