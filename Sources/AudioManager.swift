import Foundation
import AVFoundation
import AppKit
import Combine

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
    }

    @Published private(set) var allTracks: [Track] = []
    @Published private(set) var filteredTracks: [Track] = []
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false

    @Published var isShuffle: Bool {
        didSet { UserDefaults.standard.set(isShuffle, forKey: Keys.isShuffle) }
    }

    @Published var sourceFilter: MusicSourceFilter {
        didSet {
            UserDefaults.standard.set(sourceFilter.rawValue, forKey: Keys.sourceFilter)
            applyFilter()
        }
    }

    @Published var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: Keys.musicVolume)
            musicPlayer?.volume = musicVolume
        }
    }

    @Published var isFireplacePlaying: Bool = false
    @Published var fireplaceVolume: Float {
        didSet {
            UserDefaults.standard.set(fireplaceVolume, forKey: Keys.fireplaceVolume)
            fireplacePlayer?.volume = fireplaceVolume
        }
    }

    @Published private(set) var customTrackCount: Int = 0
    @Published private(set) var builtInTrackCount: Int = 0

    private var musicPlayer: AVAudioPlayer?
    private var fireplacePlayer: AVAudioPlayer?
    private let supportedExtensions: Set<String> = ["mp3", "m4a", "wav", "aac", "aiff", "flac"]

    private override init() {
        let defaults = UserDefaults.standard
        self.musicVolume = defaults.object(forKey: Keys.musicVolume) as? Float ?? 0.72
        self.fireplaceVolume = defaults.object(forKey: Keys.fireplaceVolume) as? Float ?? 0.45
        self.isShuffle = defaults.object(forKey: Keys.isShuffle) as? Bool ?? false

        if let rawFilter = defaults.string(forKey: Keys.sourceFilter),
           let filter = MusicSourceFilter(rawValue: rawFilter) {
            self.sourceFilter = filter
        } else {
            self.sourceFilter = .all
        }

        super.init()
        reloadTracks()
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
    }

    func playTrack(_ track: Track) {
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
            player.prepareToPlay()
            if player.play() {
                self.musicPlayer = player
                self.isPlaying = true
            } else {
                self.isPlaying = false
            }
        } catch {
            NSLog("NavidadBar audio error: \(error.localizedDescription)")
            self.isPlaying = false
        }
    }

    func nextTrack() {
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
            NSLog("NavidadBar fireplace error: \(error.localizedDescription)")
            isFireplacePlaying = false
        }
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
