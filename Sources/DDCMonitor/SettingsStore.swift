import Foundation

/// UserDefaults wrapper for brightness/contrast range settings.
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let brightnessMin = "brightnessMin"
        static let brightnessMax = "brightnessMax"
        static let contrastMin = "contrastMin"
        static let contrastMax = "contrastMax"
        static let step = "step"
        static let dayBrightness = "dayBrightness"
        static let dayContrast = "dayContrast"
        static let nightBrightness = "nightBrightness"
        static let nightContrast = "nightContrast"
        static let lastBrightness = "lastBrightness"
        static let lastContrast = "lastContrast"
        static let volumeMin = "volumeMin"
        static let volumeMax = "volumeMax"
        static let lastVolume = "lastVolume"
    }

    var brightnessMin: Int {
        get { defaults.object(forKey: Keys.brightnessMin) as? Int ?? 15 }
        set { defaults.set(newValue, forKey: Keys.brightnessMin) }
    }

    var brightnessMax: Int {
        get { defaults.object(forKey: Keys.brightnessMax) as? Int ?? 75 }
        set { defaults.set(newValue, forKey: Keys.brightnessMax) }
    }

    var contrastMin: Int {
        get { defaults.object(forKey: Keys.contrastMin) as? Int ?? 25 }
        set { defaults.set(newValue, forKey: Keys.contrastMin) }
    }

    var contrastMax: Int {
        get { defaults.object(forKey: Keys.contrastMax) as? Int ?? 90 }
        set { defaults.set(newValue, forKey: Keys.contrastMax) }
    }

    /// Number of hotkey steps from min to max.
    var hotkeySteps: Int {
        get { defaults.object(forKey: Keys.step) as? Int ?? 16 }
        set { defaults.set(newValue, forKey: Keys.step) }
    }

    var step: Int {
        get { defaults.object(forKey: Keys.step) as? Int ?? 16 }
        set { defaults.set(newValue, forKey: Keys.step) }
    }

    // MARK: - Presets

    var dayBrightness: Int {
        get { defaults.object(forKey: Keys.dayBrightness) as? Int ?? 70 }
        set { defaults.set(newValue, forKey: Keys.dayBrightness) }
    }

    var dayContrast: Int {
        get { defaults.object(forKey: Keys.dayContrast) as? Int ?? 50 }
        set { defaults.set(newValue, forKey: Keys.dayContrast) }
    }

    var nightBrightness: Int {
        get { defaults.object(forKey: Keys.nightBrightness) as? Int ?? 20 }
        set { defaults.set(newValue, forKey: Keys.nightBrightness) }
    }

    var nightContrast: Int {
        get { defaults.object(forKey: Keys.nightContrast) as? Int ?? 30 }
        set { defaults.set(newValue, forKey: Keys.nightContrast) }
    }

    // MARK: - Last Known Values

    var lastBrightness: Int? {
        get { defaults.object(forKey: Keys.lastBrightness) as? Int }
        set { defaults.set(newValue, forKey: Keys.lastBrightness) }
    }

    var lastContrast: Int? {
        get { defaults.object(forKey: Keys.lastContrast) as? Int }
        set { defaults.set(newValue, forKey: Keys.lastContrast) }
    }

    var volumeMin: Int {
        get { defaults.object(forKey: Keys.volumeMin) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Keys.volumeMin) }
    }

    var volumeMax: Int {
        get { defaults.object(forKey: Keys.volumeMax) as? Int ?? 100 }
        set { defaults.set(newValue, forKey: Keys.volumeMax) }
    }

    var lastVolume: Int? {
        get { defaults.object(forKey: Keys.lastVolume) as? Int }
        set { defaults.set(newValue, forKey: Keys.lastVolume) }
    }
}
