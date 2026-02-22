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
    }

    var brightnessMin: Int {
        get { defaults.object(forKey: Keys.brightnessMin) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Keys.brightnessMin) }
    }

    var brightnessMax: Int {
        get { defaults.object(forKey: Keys.brightnessMax) as? Int ?? 100 }
        set { defaults.set(newValue, forKey: Keys.brightnessMax) }
    }

    var contrastMin: Int {
        get { defaults.object(forKey: Keys.contrastMin) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Keys.contrastMin) }
    }

    var contrastMax: Int {
        get { defaults.object(forKey: Keys.contrastMax) as? Int ?? 100 }
        set { defaults.set(newValue, forKey: Keys.contrastMax) }
    }

    var step: Int {
        get { defaults.object(forKey: Keys.step) as? Int ?? 5 }
        set { defaults.set(newValue, forKey: Keys.step) }
    }
}
