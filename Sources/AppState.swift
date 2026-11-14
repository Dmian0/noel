import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case es = "es"
    case en = "en"

    var id: String { rawValue }

    var shortLabel: String {
        self == .es ? "ES" : "EN"
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark = "dark"
    case light = "light"
    case system = "system"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .dark: return lang == .en ? "Pine Dark" : "Pino Dark"
        case .light: return lang == .en ? "Cream Light" : "Crema Light"
        case .system: return "Auto"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum AppFontStyle: String, CaseIterable, Identifiable {
    case typewriter = "typewriter"
    case optima = "optima"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .typewriter: return "Typewriter"
        case .optima: return "Optima"
        }
    }
}

enum CharacterType: String, CaseIterable, Identifiable {
    case tree = "tree"
    case snowman = "snowman"
    case reindeer = "reindeer"
    case santa = "santa"
    case hotCocoa = "hotCocoa"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .tree: return lang == .en ? "Tree" : "Pinito"
        case .snowman: return lang == .en ? "Snowman" : "Muñeco"
        case .reindeer: return lang == .en ? "Reindeer" : "Reno"
        case .santa: return lang == .en ? "Santa" : "Santa"
        case .hotCocoa: return lang == .en ? "Cocoa" : "Chocolate"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }

    var emoji: String {
        switch self {
        case .tree: return "🎄"
        case .snowman: return "⛄"
        case .reindeer: return "🦌"
        case .santa: return "🎅"
        case .hotCocoa: return "☕"
        }
    }
}

enum IconStyle: String, CaseIterable, Identifiable {
    case colorful = "colorful"
    case pixelArt = "pixelArt"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .colorful: return lang == .en ? "3D Color" : "Color 3D"
        case .pixelArt: return "Pixel Art"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum AnimationMode: String, CaseIterable, Identifiable {
    case always = "always"
    case onlyWhenPlaying = "onlyWhenPlaying"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .always: return lang == .en ? "Always spin" : "Girar siempre"
        case .onlyWhenPlaying: return lang == .en ? "Spin with music" : "Girar con música"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum LightsPattern: String, CaseIterable, Identifiable {
    case twinkle = "twinkle"
    case wave = "wave"
    case warmSteady = "warmSteady"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .twinkle: return lang == .en ? "Twinkle" : "Parpadeo"
        case .wave: return lang == .en ? "Wave" : "Ola"
        case .warmSteady: return lang == .en ? "Warm glow" : "Cálida"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum SnowIntensityOption: Double, CaseIterable, Identifiable {
    case light = 0.3
    case medium = 0.6
    case heavy = 1.0

    var id: Double { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .light: return lang == .en ? "Light" : "Suave"
        case .medium: return lang == .en ? "Medium" : "Media"
        case .heavy: return lang == .en ? "Blizzard" : "Nevada"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum ScreenTargetMode: String, CaseIterable, Identifiable {
    case allScreens = "allScreens"
    case mainOnly = "mainOnly"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .allScreens: return lang == .en ? "All" : "Todas"
        case .mainOnly: return lang == .en ? "Main Only" : "Principal"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

final class AppState: ObservableObject {
    static let shared = AppState()

    private enum Keys {
        static let selectedCharacter = "navidadbar.selectedCharacter"
        static let iconStyle = "navidadbar.iconStyle"
        static let animationMode = "navidadbar.animationMode"
        static let showCountdownInMenuBar = "navidadbar.showCountdownInMenuBar"
        static let isSnowing = "navidadbar.isSnowing"
        static let snowIntensity = "navidadbar.snowIntensity"
        static let showTopLights = "navidadbar.showTopLights"
        static let lightsPattern = "navidadbar.lightsPattern"
        static let customMusicFolderPath = "navidadbar.customMusicFolderPath"
        static let themeMode = "noel.themeMode"
        static let fontStyle = "noel.fontStyle"
        static let language = "noel.language"
        static let screenTargetMode = "noel.screenTargetMode"
    }

    static var languageStorageKey: String {
        "navidadbar.language.\(Bundle.main.bundleIdentifier ?? "default")"
    }

    var appTitle: String { "Noël" }

    @Published var themeMode: AppThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: Keys.themeMode) }
    }

    @Published var fontStyle: AppFontStyle {
        didSet { UserDefaults.standard.set(fontStyle.rawValue, forKey: Keys.fontStyle) }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
            UserDefaults.standard.set(language.rawValue, forKey: AppState.languageStorageKey)
        }
    }

    @Published var selectedCharacter: CharacterType {
        didSet { UserDefaults.standard.set(selectedCharacter.rawValue, forKey: Keys.selectedCharacter) }
    }

    @Published var iconStyle: IconStyle {
        didSet { UserDefaults.standard.set(iconStyle.rawValue, forKey: Keys.iconStyle) }
    }

    @Published var animationMode: AnimationMode {
        didSet { UserDefaults.standard.set(animationMode.rawValue, forKey: Keys.animationMode) }
    }

    @Published var showCountdownInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showCountdownInMenuBar, forKey: Keys.showCountdownInMenuBar) }
    }

    @Published var isSnowing: Bool {
        didSet {
            UserDefaults.standard.set(isSnowing, forKey: Keys.isSnowing)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var snowIntensity: Double {
        didSet {
            UserDefaults.standard.set(snowIntensity, forKey: Keys.snowIntensity)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var showTopLights: Bool {
        didSet {
            UserDefaults.standard.set(showTopLights, forKey: Keys.showTopLights)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var lightsPattern: LightsPattern {
        didSet {
            UserDefaults.standard.set(lightsPattern.rawValue, forKey: Keys.lightsPattern)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var customMusicFolderPath: String? {
        didSet { UserDefaults.standard.set(customMusicFolderPath, forKey: Keys.customMusicFolderPath) }
    }

    @Published var screenTargetMode: ScreenTargetMode {
        didSet {
            UserDefaults.standard.set(screenTargetMode.rawValue, forKey: Keys.screenTargetMode)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        // Idioma: guardado o por defecto .es
        if let rawLang = defaults.string(forKey: Keys.language) ?? defaults.string(forKey: AppState.languageStorageKey),
           let lang = AppLanguage(rawValue: rawLang) {
            self.language = lang
        } else {
            self.language = .es
        }

        // Tema: guardado o por defecto .dark (Pino Dark)
        if let rawTheme = defaults.string(forKey: Keys.themeMode),
           let theme = AppThemeMode(rawValue: rawTheme) {
            self.themeMode = theme
        } else {
            self.themeMode = .dark
        }

        // Tipografía: guardada o por defecto .typewriter
        if let rawFont = defaults.string(forKey: Keys.fontStyle),
           let font = AppFontStyle(rawValue: rawFont) {
            self.fontStyle = font
        } else {
            self.fontStyle = .typewriter
        }

        if let rawChar = defaults.string(forKey: Keys.selectedCharacter),
           let char = CharacterType(rawValue: rawChar) {
            self.selectedCharacter = char
        } else {
            self.selectedCharacter = .tree
        }

        if let rawStyle = defaults.string(forKey: Keys.iconStyle),
           let style = IconStyle(rawValue: rawStyle) {
            self.iconStyle = style
        } else {
            self.iconStyle = .colorful
        }

        if let rawAnim = defaults.string(forKey: Keys.animationMode),
           let anim = AnimationMode(rawValue: rawAnim) {
            self.animationMode = anim
        } else {
            self.animationMode = .always
        }

        self.showCountdownInMenuBar = defaults.object(forKey: Keys.showCountdownInMenuBar) as? Bool ?? false
        self.isSnowing = defaults.object(forKey: Keys.isSnowing) as? Bool ?? false
        let storedSnow = defaults.object(forKey: Keys.snowIntensity) as? Double ?? 0.6
        self.snowIntensity = storedSnow > 0 ? storedSnow : 0.6
        self.showTopLights = defaults.object(forKey: Keys.showTopLights) as? Bool ?? false

        if let rawPattern = defaults.string(forKey: Keys.lightsPattern),
           let pattern = LightsPattern(rawValue: rawPattern) {
            self.lightsPattern = pattern
        } else {
            self.lightsPattern = .twinkle
        }

        self.customMusicFolderPath = defaults.string(forKey: Keys.customMusicFolderPath)

        if let rawScreenMode = defaults.string(forKey: Keys.screenTargetMode),
           let mode = ScreenTargetMode(rawValue: rawScreenMode) {
            self.screenTargetMode = mode
        } else {
            self.screenTargetMode = .allScreens
        }
    }

    func countdownToChristmas(from now: Date = Date()) -> (days: Int, hours: Int, isChristmasToday: Bool) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let year = components.year else { return (0, 0, false) }

        if components.month == 12 && components.day == 25 {
            return (0, 0, true)
        }

        var targetComponents = DateComponents(year: year, month: 12, day: 25, hour: 0, minute: 0, second: 0)
        var targetDate = calendar.date(from: targetComponents) ?? now

        if targetDate <= now {
            targetComponents.year = year + 1
            targetDate = calendar.date(from: targetComponents) ?? now
        }

        let diff = calendar.dateComponents([.day, .hour], from: now, to: targetDate)
        return (max(0, diff.day ?? 0), max(0, diff.hour ?? 0), false)
    }

    func countdownShortText(from now: Date = Date()) -> String {
        let info = countdownToChristmas(from: now)
        if info.isChristmasToday {
            return language == .en ? "TODAY" : "HOY"
        }
        return "\(info.days)D"
    }

    func countdownLongText(from now: Date = Date()) -> String {
        let info = countdownToChristmas(from: now)
        if info.isChristmasToday {
            return language == .en ? "Today is Christmas! Happy Holidays!" : "¡Hoy es Navidad! ¡Felices fiestas!"
        }
        if language == .en {
            let dayWord = info.days == 1 ? "day" : "days"
            return "\(info.days) \(dayWord) & \(info.hours) h until Christmas"
        } else {
            let dayWord = info.days == 1 ? "día" : "días"
            return "Faltan \(info.days) \(dayWord) y \(info.hours) h para Navidad"
        }
    }
}
