import Foundation
import AVFoundation
import AppKit
import Combine

enum MusicPlayerProvider: String, CaseIterable, Identifiable {
    case noel = "noel"
    case spotify = "spotify"
    case appleMusic = "appleMusic"

    var id: String { rawValue }

    var bundleIdentifier: String? {
        switch self {
        case .noel: return nil
        case .spotify: return "com.spotify.client"
        case .appleMusic: return "com.apple.Music"
        }
    }

    var displayName: String {
        switch self {
        case .noel: return "Noël"
        case .spotify: return "Spotify"
        case .appleMusic: return "Apple Music"
        }
    }
}

enum MusicSourceFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case customOnly = "customOnly"
    case builtInOnly = "builtInOnly"

    var id: String { rawValue }

    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .all: return lang == .en ? "All" : "Todas"
        case .customOnly: return lang == .en ? "My MP3s" : "Mis MP3"
        case .builtInOnly: return lang == .en ? "Built-in" : "Integradas"
        }
    }

    var displayName: String {
        displayName(in: AppState.shared.language)
    }
}

struct Track: Identifiable, Equatable {
    let id: String
    let title: String
    let titleEN: String?
    let isBuiltIn: Bool
    let builtInIndex: Int?
    let fileURL: URL?

    init(
        id: String,
        title: String,
        titleEN: String? = nil,
        isBuiltIn: Bool,
        builtInIndex: Int? = nil,
        fileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.titleEN = titleEN
        self.isBuiltIn = isBuiltIn
        self.builtInIndex = builtInIndex
        self.fileURL = fileURL
    }

    var localizedTitle: String {
        if isBuiltIn && AppState.shared.language == .en {
            return titleEN ?? title
        }
        return title
    }

    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

final class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()

    private enum Keys {
        static let musicVolume = "navidadbar.musicVolume"
        static let fireplaceVolume = "navidadbar.fireplaceVolume"
        static let isShuffle = "navidadbar.isShuffle"
        static let sourceFilter = "navidadbar.sourceFilter"
        static let musicProvider = "noel.musicProvider"
        static let windVolume = "noel.windVolume"
    }

    @Published var musicProvider: MusicPlayerProvider {
        didSet {
            UserDefaults.standard.set(musicProvider.rawValue, forKey: Keys.musicProvider)
            handleProviderChanged(from: oldValue, to: musicProvider)
        }
    }

    @Published private(set) var externalTrackTitle: String? = nil
    @Published private(set) var externalTrackArtist: String? = nil
    @Published private(set) var isExternalAppRunning: Bool = false

    @Published private(set) var allTracks: [Track] = []
    @Published private(set) var filteredTracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false

    @Published var isShuffle: Bool {
        didSet {
            if musicProvider == .noel && !isUpdatingFromExternal {
                UserDefaults.standard.set(isShuffle, forKey: Keys.isShuffle)
            } else if !isUpdatingFromExternal, let bundleID = musicProvider.bundleIdentifier {
                let shuffleProp = (musicProvider == .spotify) ? "shuffling" : "shuffle enabled"
                let script = "tell application id \"\(bundleID)\" to set \(shuffleProp) to \(isShuffle)"
                appleScriptQueue.async {
                    NSAppleScript(source: script)?.executeAndReturnError(nil)
                }
            }
        }
    }

    @Published var sourceFilter: MusicSourceFilter {
        didSet {
            UserDefaults.standard.set(sourceFilter.rawValue, forKey: Keys.sourceFilter)
            applyFilter()
        }
    }

    @Published var musicVolume: Float {
        didSet {
            if musicProvider == .noel {
                if !isUpdatingFromExternal {
                    UserDefaults.standard.set(musicVolume, forKey: Keys.musicVolume)
                }
                musicPlayer?.volume = musicVolume
            } else if !isUpdatingFromExternal, let bundleID = musicProvider.bundleIdentifier {
                let volInt = max(0, min(100, Int(musicVolume * 100)))
                let script = "tell application id \"\(bundleID)\" to set sound volume to \(volInt)"
                appleScriptQueue.async {
                    NSAppleScript(source: script)?.executeAndReturnError(nil)
                }
            }
        }
    }

    @Published var isFireplacePlaying: Bool = false
    @Published var fireplaceVolume: Float {
        didSet {
            UserDefaults.standard.set(fireplaceVolume, forKey: Keys.fireplaceVolume)
            fireplacePlayer?.volume = fireplaceVolume
        }
    }

    @Published var isWindPlaying: Bool = false
    @Published var windVolume: Float {
        didSet {
            UserDefaults.standard.set(windVolume, forKey: Keys.windVolume)
            windPlayer?.volume = windVolume
        }
    }

    @Published private(set) var customTrackCount: Int = 0
    @Published private(set) var builtInTrackCount: Int = 0

    private var musicPlayer: AVAudioPlayer?
    private var fireplacePlayer: AVAudioPlayer?
    private var sleighPlayer: AVAudioPlayer?
    private var windPlayer: AVAudioPlayer?
    private var wasBlizzardActive: Bool = false
    private let supportedExtensions: Set<String> = ["mp3", "m4a", "wav", "aac", "aiff", "flac"]

    private var isUpdatingFromExternal = false
    private var externalSyncTimer: Timer?
    private let appleScriptQueue = DispatchQueue(label: "com.damiatorres.noel.applescript", qos: .userInitiated)

    private override init() {
        let defaults = UserDefaults.standard
        self.musicVolume = defaults.object(forKey: Keys.musicVolume) as? Float ?? 0.72
        self.fireplaceVolume = defaults.object(forKey: Keys.fireplaceVolume) as? Float ?? 0.45
        self.windVolume = defaults.object(forKey: Keys.windVolume) as? Float ?? 0.38
        self.isShuffle = defaults.object(forKey: Keys.isShuffle) as? Bool ?? false

        if let rawFilter = defaults.string(forKey: Keys.sourceFilter),
           let filter = MusicSourceFilter(rawValue: rawFilter) {
            self.sourceFilter = filter
        } else {
            self.sourceFilter = .all
        }

        if let rawProvider = defaults.string(forKey: Keys.musicProvider),
           let provider = MusicPlayerProvider(rawValue: rawProvider) {
            self.musicProvider = provider
        } else {
            self.musicProvider = .noel
        }

        super.init()
        reloadTracks()
        setupDistributedNotifications()

        if musicProvider != .noel {
            startExternalSyncTimer()
            syncExternalPlayerState()
        }
    }

    private func handleProviderChanged(from old: MusicPlayerProvider, to new: MusicPlayerProvider) {
        if old == .noel && new != .noel {
            // Pause local music box while keeping hearth/fireplace untouched
            musicPlayer?.pause()
        }

        if new == .noel {
            // Restore local player state
            isPlaying = (musicPlayer?.isPlaying == true)
            isUpdatingFromExternal = true
            musicVolume = UserDefaults.standard.object(forKey: Keys.musicVolume) as? Float ?? 0.72
            isShuffle = UserDefaults.standard.object(forKey: Keys.isShuffle) as? Bool ?? false
            isUpdatingFromExternal = false
            externalTrackTitle = nil
            externalTrackArtist = nil
            isExternalAppRunning = false
            stopExternalSyncTimer()
        } else {
            startExternalSyncTimer()
            syncExternalPlayerState()
        }
    }

    private func startExternalSyncTimer() {
        stopExternalSyncTimer()
        let timer = Timer(timeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.syncExternalPlayerState()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.externalSyncTimer = timer
    }

    private func stopExternalSyncTimer() {
        externalSyncTimer?.invalidate()
        externalSyncTimer = nil
    }

    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            self,
            selector: #selector(handleSpotifyNotification(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleAppleMusicNotification(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
    }

    @objc private func handleSpotifyNotification(_ notification: Notification) {
        guard musicProvider == .spotify else { return }
        handleExternalNotification(notification)
    }

    @objc private func handleAppleMusicNotification(_ notification: Notification) {
        guard musicProvider == .appleMusic else { return }
        handleExternalNotification(notification)
    }

    private func handleExternalNotification(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let stateStr = (info["Player State"] as? String) ?? ""
        let nameStr = (info["Name"] as? String) ?? ""
        let artistStr = (info["Artist"] as? String) ?? ""

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isPlay = stateStr.caseInsensitiveCompare("Playing") == .orderedSame
            self.isPlaying = isPlay
            self.externalTrackTitle = nameStr.isEmpty ? nil : nameStr
            self.externalTrackArtist = artistStr.isEmpty ? nil : artistStr
            self.isExternalAppRunning = true
        }
    }

    func syncExternalPlayerState() {
        guard let bundleID = musicProvider.bundleIdentifier else { return }

        appleScriptQueue.async { [weak self] in
            guard let self = self else { return }

            let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil
            guard isRunning else {
                DispatchQueue.main.async {
                    guard self.musicProvider.bundleIdentifier == bundleID else { return }
                    self.isExternalAppRunning = false
                    self.isPlaying = false
                    self.externalTrackTitle = nil
                    self.externalTrackArtist = nil
                }
                return
            }

            let scriptSource: String
            if self.musicProvider == .spotify {
                scriptSource = """
                tell application id "com.spotify.client"
                    set pState to player state as string
                    set tName to ""
                    set tArtist to ""
                    try
                        set tName to name of current track
                    end try
                    try
                        set tArtist to artist of current track
                    end try
                    set sVol to sound volume
                    set sShuffle to shuffling
                    return pState & "|||NOEL_SEP|||" & tName & "|||NOEL_SEP|||" & tArtist & "|||NOEL_SEP|||" & (sVol as string) & "|||NOEL_SEP|||" & (sShuffle as string)
                end tell
                """
            } else {
                scriptSource = """
                tell application id "com.apple.Music"
                    set pState to player state as string
                    set tName to ""
                    set tArtist to ""
                    try
                        set tName to name of current track
                    end try
                    try
                        set tArtist to artist of current track
                    end try
                    set sVol to sound volume
                    set sShuffle to shuffle enabled
                    return pState & "|||NOEL_SEP|||" & tName & "|||NOEL_SEP|||" & tArtist & "|||NOEL_SEP|||" & (sVol as string) & "|||NOEL_SEP|||" & (sShuffle as string)
                end tell
                """
            }

            var errorInfo: NSDictionary?
            let appleScript = NSAppleScript(source: scriptSource)
            let resultDescriptor = appleScript?.executeAndReturnError(&errorInfo)

            guard let output = resultDescriptor?.stringValue else { return }
            let parts = output.components(separatedBy: "|||NOEL_SEP|||")
            guard parts.count >= 5 else { return }

            let pState = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let tName = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let tArtist = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let sVol = Float(parts[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 70.0
            let sShuffle = parts[4].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"

            let isNowPlaying = pState.caseInsensitiveCompare("playing") == .orderedSame || pState.lowercased().contains("play")
            let normalizedVolume = max(0.0, min(1.0, sVol / 100.0))

            DispatchQueue.main.async {
                guard self.musicProvider.bundleIdentifier == bundleID else { return }
                self.isExternalAppRunning = true
                self.isPlaying = isNowPlaying
                self.externalTrackTitle = tName.isEmpty ? nil : tName
                self.externalTrackArtist = tArtist.isEmpty ? nil : tArtist

                self.isUpdatingFromExternal = true
                self.musicVolume = normalizedVolume
                self.isShuffle = sShuffle
                self.isUpdatingFromExternal = false
            }
        }
    }

    func openActiveExternalApp() {
        guard let bundleID = musicProvider.bundleIdentifier else { return }
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
        }
    }

    var displayTrackTitle: String {
        let isEN = AppState.shared.language == .en
        switch musicProvider {
        case .noel:
            if let current = currentTrack {
                return current.localizedTitle
            }
            return isEN ? "No music selected" : "Sin música seleccionada"
        case .spotify, .appleMusic:
            if let title = externalTrackTitle, !title.isEmpty {
                return title
            }
            if isExternalAppRunning {
                return isEN ? "\(musicProvider.displayName) — Ready" : "\(musicProvider.displayName) — Listo"
            } else {
                return isEN ? "\(musicProvider.displayName) not running" : "\(musicProvider.displayName) no abierto"
            }
        }
    }

    var displayTrackSubtitle: String {
        let isEN = AppState.shared.language == .en
        switch musicProvider {
        case .noel:
            if currentTrack != nil {
                return isEN ? "Noël Music Box" : "Caja de música Noël"
            }
            return isEN ? "Built-in / Local MP3" : "Integradas / Mis MP3"
        case .spotify, .appleMusic:
            if let artist = externalTrackArtist, !artist.isEmpty {
                return artist
            }
            return musicProvider.displayName
        }
    }

    func reloadTracks() {
        var collected: [Track] = []
        var customCount = 0
        var seenPaths = Set<String>()

        // 1. Scan custom folder chosen by user
        if let customPath = AppState.shared.customMusicFolderPath, !customPath.isEmpty {
            let folderURL = URL(fileURLWithPath: customPath)
            let found = scanAudioFiles(in: folderURL, seenPaths: &seenPaths)
            customCount += found.count
            collected.append(contentsOf: found)
        }

        // 2. Scan local ./MusicaNavidad folders (beside .app bundle or CWD)
        for localFolder in localMusicFolders() {
            let found = scanAudioFiles(in: localFolder, seenPaths: &seenPaths)
            customCount += found.count
            collected.append(contentsOf: found)
        }

        // 3. Built-in synthesized Christmas music-box songs
        let builtIns = AudioSynthesizer.shared.builtInSongs.map { info in
            Track(
                id: "builtin-\(info.index)",
                title: info.title,
                titleEN: info.titleEN,
                isBuiltIn: true,
                builtInIndex: info.index,
                fileURL: nil
            )
        }
        collected.append(contentsOf: builtIns)

        self.customTrackCount = customCount
        self.builtInTrackCount = builtIns.count
        self.allTracks = collected
        applyFilter()
    }

    private func localMusicFolders() -> [URL] {
        var candidates: [URL] = []
        let bundleParent = Bundle.main.bundleURL.deletingLastPathComponent()
        candidates.append(bundleParent.appendingPathComponent("MusicaNavidad"))

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        candidates.append(cwd.appendingPathComponent("MusicaNavidad"))

        return candidates
    }

    private func scanAudioFiles(in directory: URL, seenPaths: inout Set<String>) -> [Track] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return []
        }

        guard let items = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let sorted = items.sorted {
            $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending
        }

        var tracks: [Track] = []
        for url in sorted {
            let ext = url.pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else { continue }
            let resolved = url.resolvingSymlinksInPath().path
            guard !seenPaths.contains(resolved) else { continue }
            seenPaths.insert(resolved)

            let title = url.deletingPathExtension().lastPathComponent
            tracks.append(Track(
                id: "file-\(resolved)",
                title: title,
                isBuiltIn: false,
                builtInIndex: nil,
                fileURL: url
            ))
        }
        return tracks
    }

    private func applyFilter() {
        switch sourceFilter {
        case .all:
            filteredTracks = allTracks
        case .customOnly:
            let custom = allTracks.filter { !$0.isBuiltIn }
            filteredTracks = custom
        case .builtInOnly:
            filteredTracks = allTracks.filter { $0.isBuiltIn }
        }

        if let current = currentTrack, filteredTracks.contains(current) {
            return
        }
        currentTrack = filteredTracks.first ?? allTracks.first
    }

    func chooseMusicFolder() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let panel = NSOpenPanel()
            let isEN = AppState.shared.language == .en
            panel.title = isEN ? "Choose Christmas Music Folder" : "Elegir carpeta con música navideña"
            panel.message = isEN ? "Select a folder containing your MP3, M4A, or WAV files" : "Selecciona una carpeta que contenga tus archivos MP3, M4A o WAV"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true

            if let currentPath = AppState.shared.customMusicFolderPath {
                panel.directoryURL = URL(fileURLWithPath: currentPath)
            }

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                AppState.shared.customMusicFolderPath = url.path
                self.reloadTracks()
                if self.customTrackCount > 0 {
                    if self.sourceFilter == .builtInOnly {
                        self.sourceFilter = .all
                    }
                    if let firstCustom = self.filteredTracks.first(where: { !$0.isBuiltIn }) {
                        self.playTrack(firstCustom)
                    }
                }
            }
        }
    }

    func clearCustomFolder() {
        AppState.shared.customMusicFolderPath = nil
        if sourceFilter == .customOnly {
            sourceFilter = .all
        }
        reloadTracks()
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        if musicProvider == .noel {
            if isPlaying {
                musicPlayer?.pause()
                isPlaying = false
                return
            }

            if let player = musicPlayer, currentTrack != nil {
                player.volume = musicVolume
                if player.play() {
                    isPlaying = true
                    return
                }
            }

            if let track = currentTrack ?? filteredTracks.first ?? allTracks.first {
                playTrack(track)
            }
            return
        }

        // Spotify / Apple Music
        guard let bundleID = musicProvider.bundleIdentifier else { return }
        let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil

        if !isRunning {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = false
                NSWorkspace.shared.openApplication(at: appURL, configuration: config) { [weak self] _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        self?.appleScriptQueue.async {
                            let playScript = "tell application id \"\(bundleID)\" to play"
                            NSAppleScript(source: playScript)?.executeAndReturnError(nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                self?.syncExternalPlayerState()
                            }
                        }
                    }
                }
            }
            return
        }

        // Running: flip isPlaying optimistically and send playpause
        isPlaying.toggle()
        appleScriptQueue.async { [weak self] in
            let script = "tell application id \"\(bundleID)\" to playpause"
            NSAppleScript(source: script)?.executeAndReturnError(nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.syncExternalPlayerState()
            }
        }
    }

    func playTrack(_ track: Track) {
        if musicProvider != .noel {
            musicProvider = .noel
        }

        currentTrack = track
        musicPlayer?.stop()
        musicPlayer = nil

        do {
            let player: AVAudioPlayer
            if track.isBuiltIn, let index = track.builtInIndex {
                let wavData = AudioSynthesizer.shared.wavDataForBuiltInSong(index: index)
                player = try AVAudioPlayer(data: wavData, fileTypeHint: AVFileType.wav.rawValue)
            } else if let url = track.fileURL {
                player = try AVAudioPlayer(contentsOf: url)
            } else {
                isPlaying = false
                return
            }

            player.delegate = self
            player.volume = musicVolume
            player.isMeteringEnabled = true
            player.prepareToPlay()
            if player.play() {
                self.musicPlayer = player
                self.isPlaying = true
            } else {
                self.isPlaying = false
            }
        } catch {
            NSLog("Noël audio error: \(error.localizedDescription)")
            self.isPlaying = false
        }
    }

    func nextTrack() {
        if musicProvider != .noel {
            guard let bundleID = musicProvider.bundleIdentifier else { return }
            appleScriptQueue.async { [weak self] in
                let script = "tell application id \"\(bundleID)\" to next track"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.syncExternalPlayerState()
                }
            }
            return
        }

        let list = activePlaylist()
        guard !list.isEmpty else { return }

        if isShuffle && list.count > 1 {
            let candidates = list.filter { $0 != currentTrack }
            if let next = candidates.randomElement() ?? list.first {
                playTrack(next)
            }
            return
        }

        if let current = currentTrack, let idx = list.firstIndex(of: current) {
            let nextIdx = (idx + 1) % list.count
            playTrack(list[nextIdx])
        } else if let first = list.first {
            playTrack(first)
        }
    }

    func previousTrack() {
        if musicProvider != .noel {
            guard let bundleID = musicProvider.bundleIdentifier else { return }
            appleScriptQueue.async { [weak self] in
                let script = "tell application id \"\(bundleID)\" to previous track"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.syncExternalPlayerState()
                }
            }
            return
        }

        let list = activePlaylist()
        guard !list.isEmpty else { return }

        if let player = musicPlayer, player.currentTime > 3.0 {
            player.currentTime = 0
            if !isPlaying {
                player.play()
                isPlaying = true
            }
            return
        }

        if let current = currentTrack, let idx = list.firstIndex(of: current) {
            let prevIdx = (idx - 1 + list.count) % list.count
            playTrack(list[prevIdx])
        } else if let first = list.first {
            playTrack(first)
        }
    }

    private func activePlaylist() -> [Track] {
        return filteredTracks.isEmpty ? allTracks : filteredTracks
    }

    // MARK: - Fireplace Ambient Audio

    func toggleFireplace() {
        setFireplacePlaying(!isFireplacePlaying)
    }

    func setFireplacePlaying(_ enabled: Bool) {
        if !enabled {
            fireplacePlayer?.stop()
            isFireplacePlaying = false
            return
        }

        if let existing = fireplacePlayer {
            existing.volume = fireplaceVolume
            existing.numberOfLoops = -1
            if existing.play() {
                isFireplacePlaying = true
                return
            }
        }

        do {
            let wavData = AudioSynthesizer.shared.generateFireplaceWAV()
            let player = try AVAudioPlayer(data: wavData, fileTypeHint: AVFileType.wav.rawValue)
            player.numberOfLoops = -1
            player.volume = fireplaceVolume
            player.prepareToPlay()
            if player.play() {
                fireplacePlayer = player
                isFireplacePlaying = true
            }
        } catch {
            NSLog("Noël fireplace error: \(error.localizedDescription)")
            isFireplacePlaying = false
        }
    }

    // MARK: - Santa Sleigh Audio

    func playSleighBells(leftToRight: Bool) {
        guard AppState.shared.santaSoundEnabled else { return }

        do {
            let wavData = AudioSynthesizer.shared.generateSleighBellsWAV(leftToRight: leftToRight)
            let player = try AVAudioPlayer(data: wavData, fileTypeHint: AVFileType.wav.rawValue)
            player.volume = min(0.45, max(0.18, musicVolume * 0.42))
            player.prepareToPlay()
            player.play()
            self.sleighPlayer = player
        } catch {
            NSLog("Noël sleigh audio error: \(error.localizedDescription)")
        }
    }

    // MARK: - Winter Wind Ambient Audio

    func toggleWind() {
        setWindPlaying(!isWindPlaying)
    }

    func setWindPlaying(_ enabled: Bool) {
        if !enabled {
            windPlayer?.stop()
            isWindPlaying = false
            return
        }

        if let existing = windPlayer {
            existing.volume = windVolume
            existing.numberOfLoops = -1
            if existing.play() {
                isWindPlaying = true
                return
            }
        }

        do {
            let wavData = AudioSynthesizer.shared.generateWinterWindWAV()
            let player = try AVAudioPlayer(data: wavData, fileTypeHint: AVFileType.wav.rawValue)
            player.numberOfLoops = -1
            player.volume = windVolume
            player.prepareToPlay()
            if player.play() {
                windPlayer = player
                isWindPlaying = true
            }
        } catch {
            NSLog("Noël wind audio error: \(error.localizedDescription)")
            isWindPlaying = false
        }
    }

    func syncWinterWindWithSnow(isSnowing: Bool, intensity: Double) {
        let isBlizzardNow = isSnowing && intensity >= 0.85
        if isBlizzardNow && !wasBlizzardActive && !isWindPlaying {
            setWindPlaying(true)
        } else if !isSnowing && isWindPlaying {
            setWindPlaying(false)
        }
        wasBlizzardActive = isBlizzardNow
    }

    // MARK: - Audio Levels Analysis

    func currentAudioLevels(at time: Double) -> (bass: Double, treble: Double, isActive: Bool) {
        if musicProvider == .noel, isPlaying, let player = musicPlayer, player.isPlaying {
            player.updateMeters()
            let avgDB = Double(player.averagePower(forChannel: 0))
            let peakDB = Double(player.peakPower(forChannel: 0))
            let avgNorm = max(0.0, min(1.0, (avgDB + 42.0) / 42.0))
            let peakNorm = max(0.0, min(1.0, (peakDB + 35.0) / 35.0))
            let bass = max(0.16, min(1.0, pow(avgNorm, 0.85) * (0.80 + 0.20 * sin(time * 6.2))))
            let treble = max(0.16, min(1.0, pow(peakNorm, 0.75) * (0.78 + 0.22 * abs(cos(time * 11.5)))))
            return (bass, treble, true)
        }

        if musicProvider != .noel && isPlaying {
            let beatPhase = time * (124.0 / 60.0) * 2.0 * .pi
            let bassPulse = pow(0.5 + 0.5 * sin(beatPhase), 2.2)
            let treblePulse = pow(0.5 + 0.5 * cos(beatPhase * 2.0 + 0.8), 1.8)
            let bass = 0.22 + 0.68 * bassPulse
            let treble = 0.20 + 0.70 * treblePulse
            return (bass, treble, true)
        }

        return (0.24 + 0.08 * sin(time * 1.5), 0.24 + 0.08 * cos(time * 1.9), false)
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === musicPlayer {
            DispatchQueue.main.async {
                if flag {
                    self.nextTrack()
                } else {
                    self.isPlaying = false
                }
            }
        }
    }
}
