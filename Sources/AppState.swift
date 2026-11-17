import Foundation
import Combine
import ServiceManagement

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
    case rhythm = "rhythm"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .twinkle: return lang == .en ? "Twinkle" : "Parpadeo"
        case .wave: return lang == .en ? "Wave" : "Ola"
        case .warmSteady: return lang == .en ? "Steady" : "Fija"
        case .rhythm: return lang == .en ? "Rhythm" : "Ritmo"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum LightsPalette: String, CaseIterable, Identifiable {
    case classic = "classic"
    case warm = "warm"
    case candyCane = "candyCane"
    case nordicIce = "nordicIce"
    case pineGold = "pineGold"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .classic: return lang == .en ? "Classic" : "Clásica"
        case .warm: return lang == .en ? "Warm White" : "Blanco Cálido"
        case .candyCane: return lang == .en ? "Candy Cane" : "Caramelo"
        case .nordicIce: return lang == .en ? "Nordic Ice" : "Hielo Nórdico"
        case .pineGold: return lang == .en ? "Pine & Gold" : "Pino y Oro"
        }
    }

    func shortName(in lang: AppLanguage) -> String {
        switch self {
        case .classic: return "Multi"
        case .warm: return lang == .en ? "Warm" : "Cálida"
        case .candyCane: return lang == .en ? "Candy" : "Caram."
        case .nordicIce: return lang == .en ? "Nordic" : "Nórd."
        case .pineGold: return lang == .en ? "Pine" : "Pino"
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

enum SantaFrequency: String, CaseIterable, Identifiable {
    case off = "off"
    case occasional = "occasional"
    case frequent = "frequent"

    var id: String { rawValue }

    var intervalSeconds: TimeInterval? {
        switch self {
        case .off: return nil
        case .occasional: return 180.0
        case .frequent: return 45.0
        }
    }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .off: return lang == .en ? "Off" : "No"
        case .occasional: return lang == .en ? "Occasional" : "Ocasional"
        case .frequent: return lang == .en ? "Frequent" : "Frecuente"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

enum SnowLayerMode: String, CaseIterable, Identifiable {
    case aboveAll = "aboveAll"
    case desktopOnly = "desktopOnly"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .aboveAll: return lang == .en ? "Above all" : "Sobre todo"
        case .desktopOnly: return lang == .en ? "Desktop" : "Escritorio"
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
        static let santaFrequency = "noel.santaFrequency"
        static let santaSoundEnabled = "noel.santaSoundEnabled"
        static let snowLayerMode = "noel.snowLayerMode"
        static let lightsPalette = "noel.lightsPalette"
        static let snowflakesStyle = "noel.snowflakesStyle"
        static let snowbankStyle = "noel.snowbankStyle"
        static let lightsStyle = "noel.lightsStyle"
        static let launchAtLogin = "noel.launchAtLogin"
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
            DispatchQueue.main.async { AudioManager.shared.syncWinterWindWithSnow(isSnowing: self.isSnowing, intensity: self.snowIntensity) }
        }
    }

    @Published var snowIntensity: Double {
        didSet {
            UserDefaults.standard.set(snowIntensity, forKey: Keys.snowIntensity)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
            DispatchQueue.main.async { AudioManager.shared.syncWinterWindWithSnow(isSnowing: self.isSnowing, intensity: self.snowIntensity) }
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

    @Published var lightsPalette: LightsPalette {
        didSet {
            UserDefaults.standard.set(lightsPalette.rawValue, forKey: Keys.lightsPalette)
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

    @Published var santaFrequency: SantaFrequency {
        didSet {
            UserDefaults.standard.set(santaFrequency.rawValue, forKey: Keys.santaFrequency)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var santaSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(santaSoundEnabled, forKey: Keys.santaSoundEnabled)
        }
    }

    @Published var snowLayerMode: SnowLayerMode {
        didSet {
            UserDefaults.standard.set(snowLayerMode.rawValue, forKey: Keys.snowLayerMode)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var snowflakesStyle: IconStyle {
        didSet {
            UserDefaults.standard.set(snowflakesStyle.rawValue, forKey: Keys.snowflakesStyle)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var snowbankStyle: IconStyle {
        didSet {
            UserDefaults.standard.set(snowbankStyle.rawValue, forKey: Keys.snowbankStyle)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var lightsStyle: IconStyle {
        didSet {
            UserDefaults.standard.set(lightsStyle.rawValue, forKey: Keys.lightsStyle)
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    @Published var isEffectsPausedForCall: Bool = false {
        didSet {
            DispatchQueue.main.async { ScreenEffectsManager.shared.syncWithState() }
        }
    }

    func toggleEffectsPausedForCall() {
        isEffectsPausedForCall.toggle()
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("Noël launchAtLogin error: \(error.localizedDescription)")
            }
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

        if let rawPalette = defaults.string(forKey: Keys.lightsPalette),
           let pal = LightsPalette(rawValue: rawPalette) {
            self.lightsPalette = pal
        } else {
            self.lightsPalette = .classic
        }

        self.customMusicFolderPath = defaults.string(forKey: Keys.customMusicFolderPath)

        if let rawScreenMode = defaults.string(forKey: Keys.screenTargetMode),
           let mode = ScreenTargetMode(rawValue: rawScreenMode) {
            self.screenTargetMode = mode
        } else {
            self.screenTargetMode = .allScreens
        }

        if let rawSantaFreq = defaults.string(forKey: Keys.santaFrequency),
           let freq = SantaFrequency(rawValue: rawSantaFreq) {
            self.santaFrequency = freq
        } else {
            self.santaFrequency = .occasional
        }

        self.santaSoundEnabled = defaults.object(forKey: Keys.santaSoundEnabled) as? Bool ?? true

        if let rawSnowLayer = defaults.string(forKey: Keys.snowLayerMode),
           let mode = SnowLayerMode(rawValue: rawSnowLayer) {
            self.snowLayerMode = mode
        } else {
            self.snowLayerMode = .aboveAll
        }

        if let rawSnowflakesStyle = defaults.string(forKey: Keys.snowflakesStyle),
           let style = IconStyle(rawValue: rawSnowflakesStyle) {
            self.snowflakesStyle = style
        } else {
            self.snowflakesStyle = .colorful
        }

        if let rawSnowbankStyle = defaults.string(forKey: Keys.snowbankStyle),
           let style = IconStyle(rawValue: rawSnowbankStyle) {
            self.snowbankStyle = style
        } else {
            self.snowbankStyle = .colorful
        }

        if let rawLightsStyle = defaults.string(forKey: Keys.lightsStyle),
           let style = IconStyle(rawValue: rawLightsStyle) {
            self.lightsStyle = style
        } else {
            self.lightsStyle = .colorful
        }

        self.launchAtLogin = (SMAppService.mainApp.status == .enabled) || (defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false)
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
