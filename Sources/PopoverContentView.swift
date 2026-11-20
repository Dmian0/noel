import SwiftUI
import AppKit

// MARK: - Noël Popover Content View
struct PopoverContentView: View {
    @ObservedObject private var state = AppState.shared
    @ObservedObject private var audio = AudioManager.shared
    @Environment(\.colorScheme) private var systemColorScheme

    @State private var showSettings: Bool = false
    @State private var showTrackList: Bool = false

    private var isEn: Bool {
        state.language == .en
    }

    private var isDark: Bool {
        switch state.themeMode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return systemColorScheme == .dark
        }
    }

    // MARK: - Typography Helpers
    private func titleFont(size: CGFloat) -> Font {
        switch state.fontStyle {
        case .typewriter:
            return Font.custom("American Typewriter", size: size)
        case .optima:
            return Font.custom("Optima", size: size)
        }
    }

    private func monoFont(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Theme Color Palette
    private var primaryTextColor: Color {
        isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0x1D3B2E)
    }

    private var secondaryTextColor: Color {
        isDark ? Color(hex: 0xF4EFE6).opacity(0.62) : Color(hex: 0x6E6252)
    }

    private var accentRedColor: Color {
        isDark ? Color(hex: 0xB84A4A) : Color(hex: 0xB84237)
    }

    private var goldBrassColor: Color {
        Color(hex: 0xD4AF37)
    }

    private var surfaceCardColor: Color {
        isDark ? Color(hex: 0xF4EFE6).opacity(0.06) : Color(hex: 0xEDE3D2).opacity(0.6)
    }

    private var surfaceCardBorder: Color {
        isDark ? Color(hex: 0xF4EFE6).opacity(0.12) : Color(hex: 0xCBBBA0)
    }

    private var themeIconName: String {
        switch state.themeMode {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    private func cycleTheme() {
        switch state.themeMode {
        case .dark:
            state.themeMode = .light
        case .light:
            state.themeMode = .system
        case .system:
            state.themeMode = .dark
        }
    }

    private func toggleLanguage() {
        state.language = (state.language == .es ? .en : .es)
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            fixedHeaderView
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            ThemeDivider(isDark: isDark)
                .padding(.horizontal, 14)

            // Content
            VStack(spacing: 12) {
                if showSettings {
                    settingsContentView
                } else {
                    mainContentView
                }

                ThemeDivider(isDark: isDark)

                footerView
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            Group {
                if isDark {
                    RadialGradient(
                        colors: [Color(hex: 0x213E31), Color(hex: 0x111F18)],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 340
                    )
                } else {
                    Color(hex: 0xF6F0E4)
                }
            }
            .ignoresSafeArea()
        )
    }

    // MARK: - Fixed Header
    private var fixedHeaderView: some View {
        HStack(alignment: .center, spacing: 8) {
            // Left: "Noël" + live countdown text
            VStack(alignment: .leading, spacing: 2) {
                Text("Noël")
                    .font(titleFont(size: 19))
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)

                Text(state.countdownLongText())
                    .font(monoFont(size: 9.5, weight: .medium))
                    .foregroundColor(isDark ? Color(hex: 0xE2C15A) : Color(hex: 0xB84237))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            // Right: Theme cycle, Language toggle, Settings button
            HStack(spacing: 7) {
                // Meeting Mode (Option+Click screen effects pause/resume)
                Button(action: {
                    state.toggleEffectsPausedForCall()
                }) {
                    Image(systemName: state.isEffectsPausedForCall ? "eye.slash.fill" : "eye")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(state.isEffectsPausedForCall ? accentRedColor : secondaryTextColor)
                        .frame(width: 22, height: 22)
                        .background(state.isEffectsPausedForCall ? accentRedColor.opacity(0.15) : surfaceCardColor)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isEn ? "Pause/Resume screen effects (Option+Click)" : "Pausar/Reanudar efectos de pantalla (Option+Clic)")

                // Theme button
                Button(action: cycleTheme) {
                    Image(systemName: themeIconName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryTextColor)
                        .frame(width: 22, height: 22)
                        .background(surfaceCardColor)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isEn ? "Switch theme" : "Cambiar tema")

                // Language toggle (ES / EN)
                Button(action: toggleLanguage) {
                    Text(isEn ? "EN" : "ES")
                        .font(monoFont(size: 10, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 6)
                        .frame(height: 22)
                        .background(surfaceCardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(surfaceCardBorder, lineWidth: 1)
                        )
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isEn ? "Cambiar a Español" : "Switch to English")

                // Settings gear button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showSettings.toggle()
                    }
                }) {
                    Image(systemName: showSettings ? "xmark" : "gearshape")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(showSettings ? accentRedColor : secondaryTextColor)
                        .frame(width: 22, height: 22)
                        .background(showSettings ? accentRedColor.opacity(0.15) : surfaceCardColor)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help(isEn ? (showSettings ? "Close settings" : "Settings") : (showSettings ? "Cerrar ajustes" : "Ajustes"))
            }
        }
    }

    // MARK: - Main View Content
    private var mainContentView: some View {
        VStack(spacing: 12) {
            // Music Source Selector (Noël · Spotify · Apple Music)
            musicSourceBar

            // Hero: Vinyl Record + Now Playing Track
            heroVinylTrackSection

            // Optional dropdown track list
            if showTrackList {
                trackListDropdownSection
            }

            ThemeDivider(isDark: isDark)

            // Meeting Mode paused banner
            if state.isEffectsPausedForCall {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentRedColor)

                    Text(isEn ? "Effects paused (Meeting Mode)" : "Efectos ocultos (En Llamada)")
                        .font(monoFont(size: 9.5, weight: .medium))
                        .foregroundColor(primaryTextColor)

                    Spacer(minLength: 4)

                    Button(action: { state.isEffectsPausedForCall = false }) {
                        Text(isEn ? "Resume" : "Reanudar")
                            .font(monoFont(size: 8.5, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(accentRedColor.opacity(isDark ? 0.35 : 0.18))
                            .foregroundColor(isDark ? Color(hex: 0xF4EFE6) : accentRedColor)
                            .cornerRadius(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(accentRedColor.opacity(isDark ? 0.6 : 0.4), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(surfaceCardColor)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(accentRedColor.opacity(0.35), lineWidth: 1)
                )
            }

            // 3 Tactile Ambience Pills
            ambiencePillsRow

            // Contextual controls for active effects
            if state.isSnowing || state.showTopLights || audio.isFireplacePlaying || audio.isWindPlaying {
                activeEffectsContextualSection
            }

            // Santa Sleigh Section
            santaSleighSection
        }
    }

    // MARK: - Music Source Selector Bar
    private var musicSourceBar: some View {
        HStack(spacing: 3) {
            ForEach(MusicPlayerProvider.allCases) { provider in
                let selected = audio.musicProvider == provider
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        audio.musicProvider = provider
                    }
                }) {
                    Text(musicProviderTitle(provider))
                        .font(monoFont(size: 8.5, weight: selected ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3.5)
                        .background(
                            selected
                                ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E))
                                : Color.clear
                        )
                        .foregroundColor(
                            selected
                                ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4))
                                : secondaryTextColor
                        )
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    selected
                                        ? (isDark ? goldBrassColor.opacity(0.4) : goldBrassColor.opacity(0.6))
                                        : Color.clear,
                                    lineWidth: selected ? 1 : 0
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    private func musicProviderTitle(_ provider: MusicPlayerProvider) -> String {
        switch provider {
        case .noel: return "NOËL"
        case .spotify: return "SPOTIFY"
        case .appleMusic: return "APPLE MUSIC"
        }
    }

    // MARK: - Hero Vinyl + Track Section
    private var heroVinylTrackSection: some View {
        HStack(spacing: 12) {
            // 56x56 Rotating Vinyl Record
            TimelineView(.animation(minimumInterval: 0.08, paused: !audio.isPlaying)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let angle = audio.isPlaying ? (time * 90.0).truncatingRemainder(dividingBy: 360.0) : 0
                VinylRecordView(
                    isDark: isDark,
                    accentColor: accentRedColor,
                    goldColor: goldBrassColor
                )
                .rotationEffect(.degrees(angle))
                .frame(width: 56, height: 56)
                .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.15), radius: 4, x: 0, y: 2)
            }

            // Track details + playback controls
            VStack(alignment: .leading, spacing: 3) {
                Text(audio.displayTrackTitle)
                    .font(titleFont(size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(audio.displayTrackSubtitle)
                    .font(monoFont(size: 9.5, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Control buttons row: backward, play/pause, forward, shuffle, track list toggle
                HStack(spacing: 10) {
                    Button(action: { audio.previousTrack() }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 11))
                            .foregroundColor(primaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .help(isEn ? "Previous track" : "Canción anterior")

                    Button(action: { audio.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(accentRedColor)
                                .frame(width: 26, height: 26)
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: 0xF6F0E4))
                                .offset(x: audio.isPlaying ? 0 : 0.8)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(audio.isPlaying ? (isEn ? "Pause" : "Pausar") : (isEn ? "Play" : "Reproducir"))

                    Button(action: { audio.nextTrack() }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 11))
                            .foregroundColor(primaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .help(isEn ? "Next track" : "Siguiente canción")

                    Spacer(minLength: 0)

                    Button(action: { audio.isShuffle.toggle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: audio.isShuffle ? .bold : .regular))
                            .foregroundColor(audio.isShuffle ? goldBrassColor : secondaryTextColor)
                            .frame(width: 22, height: 22)
                            .background(audio.isShuffle ? goldBrassColor.opacity(0.18) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help(isEn ? "Shuffle" : "Modo aleatorio")

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showTrackList.toggle()
                        }
                    }) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 11, weight: showTrackList ? .bold : .regular))
                            .foregroundColor(showTrackList ? primaryTextColor : secondaryTextColor)
                            .frame(width: 22, height: 22)
                            .background(showTrackList ? surfaceCardColor : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help(isEn ? "Toggle track list" : "Lista de canciones")
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Dropdown Track List Section
    private var trackListDropdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Volume slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 9))
                    .foregroundColor(secondaryTextColor)
                Slider(value: $audio.musicVolume, in: 0...1)
                    .accentColor(accentRedColor)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 9))
                    .foregroundColor(secondaryTextColor)
            }

            if audio.musicProvider == .noel {
                // Source filter tabs
                HStack(spacing: 4) {
                    ForEach(MusicSourceFilter.allCases) { filter in
                        let selected = audio.sourceFilter == filter
                        Button(action: { audio.sourceFilter = filter }) {
                            Text(sourceFilterTitle(filter))
                                .font(monoFont(size: 9, weight: selected ? .bold : .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    selected
                                        ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E))
                                        : Color.clear
                                )
                                .foregroundColor(
                                    selected
                                        ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4))
                                        : secondaryTextColor
                                )
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(surfaceCardColor)
                .cornerRadius(6)

                // Scrollable tracks
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if audio.filteredTracks.isEmpty {
                            Text(isEn ? "NO TRACKS AVAILABLE" : "NO HAY CANCIONES DISPONIBLES")
                                .font(monoFont(size: 9))
                                .foregroundColor(secondaryTextColor)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(audio.filteredTracks) { track in
                                let isCurrent = audio.currentTrack?.id == track.id
                                Button(action: { audio.playTrack(track) }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isCurrent && audio.isPlaying ? "speaker.wave.2.fill" : (isCurrent ? "speaker.fill" : "music.note"))
                                            .font(.system(size: 9))
                                            .foregroundColor(isCurrent ? accentRedColor : secondaryTextColor)
                                            .frame(width: 12)

                                        Text(track.localizedTitle)
                                            .font(monoFont(size: 10, weight: isCurrent ? .bold : .regular))
                                            .foregroundColor(isCurrent ? primaryTextColor : secondaryTextColor)
                                            .lineLimit(1)
                                            .truncationMode(.tail)

                                        Spacer()

                                        Text(track.isBuiltIn ? (isEn ? "BOX" : "CAJA") : "MP3")
                                            .font(monoFont(size: 8))
                                            .foregroundColor(secondaryTextColor.opacity(0.8))
                                    }
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(isCurrent ? surfaceCardColor : Color.clear)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 110)
                .background(surfaceCardColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(surfaceCardBorder, lineWidth: 1)
                )
            } else {
                externalPlayerCard
            }
        }
        .padding(8)
        .background(surfaceCardColor.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    private var externalPlayerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status row
            HStack(spacing: 6) {
                Circle()
                    .fill(audio.isExternalAppRunning ? Color(hex: 0x5CB85C) : secondaryTextColor.opacity(0.45))
                    .frame(width: 7, height: 7)

                Text("\(audio.musicProvider.displayName) \(isEn ? (audio.isExternalAppRunning ? "connected" : "not running") : (audio.isExternalAppRunning ? "conectado" : "cerrado"))")
                    .font(monoFont(size: 9.5, weight: .semibold))
                    .foregroundColor(primaryTextColor)
            }

            // Current track & artist summary
            if let title = audio.externalTrackTitle, !title.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(monoFont(size: 10, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let artist = audio.externalTrackArtist, !artist.isEmpty {
                        Text(artist)
                            .font(monoFont(size: 9))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            // Action button
            Button(action: { audio.openActiveExternalApp() }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 9.5))
                    Text(isEn ? "Open \(audio.musicProvider.displayName)" : "Abrir \(audio.musicProvider.displayName)")
                        .font(monoFont(size: 9.5, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(surfaceCardColor)
                .foregroundColor(primaryTextColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(surfaceCardBorder, lineWidth: 1)
                )
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
    }

    private func sourceFilterTitle(_ filter: MusicSourceFilter) -> String {
        switch filter {
        case .all: return isEn ? "ALL" : "TODAS"
        case .customOnly: return isEn ? "MY MP3s" : "MIS MP3"
        case .builtInOnly: return isEn ? "BUILT-IN" : "INTEGRADAS"
        }
    }

    // MARK: - 3 Ambience Pills Row
    private var ambiencePillsRow: some View {
        HStack(spacing: 8) {
            // 1. SNOW
            AmbiencePillButton(
                title: isEn ? "SNOW" : "NIEVE",
                isActive: state.isSnowing,
                activeTint: isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E),
                activeTextColor: isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4),
                isDark: isDark,
                monoFont: monoFont(size: 10, weight: .semibold)
            ) {
                SnowflakeShape()
                    .stroke(lineWidth: 1.25)
                    .frame(width: 14, height: 14)
            } action: {
                state.isSnowing.toggle()
            }

            // 2. LIGHTS
            AmbiencePillButton(
                title: isEn ? "LIGHTS" : "LUCES",
                isActive: state.showTopLights,
                activeTint: isDark ? Color(hex: 0xD4AF37) : Color(hex: 0xD4AF37),
                activeTextColor: isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E),
                isDark: isDark,
                monoFont: monoFont(size: 10, weight: .semibold)
            ) {
                LightsShape()
                    .stroke(lineWidth: 1.25)
                    .frame(width: 16, height: 13)
            } action: {
                state.showTopLights.toggle()
            }

            // 3. HEARTH
            AmbiencePillButton(
                title: isEn ? "HEARTH" : "FUEGO",
                isActive: audio.isFireplacePlaying,
                activeTint: isDark ? Color(hex: 0xB84A4A) : Color(hex: 0xB84237),
                activeTextColor: Color(hex: 0xF6F0E4),
                isDark: isDark,
                monoFont: monoFont(size: 10, weight: .semibold)
            ) {
                FlameShape()
                    .fill()
                    .frame(width: 12, height: 15)
            } action: {
                audio.toggleFireplace()
            }
        }
    }

    // MARK: - Active Effects Contextual Section
    private var activeEffectsContextualSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Snow intensity row
            if state.isSnowing {
                HStack(spacing: 6) {
                    SnowflakeShape()
                        .stroke(lineWidth: 1)
                        .frame(width: 11, height: 11)
                        .foregroundColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))

                    Text(isEn ? "INTENSITY" : "INTENSIDAD")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach(SnowIntensityOption.allCases) { opt in
                            let isSelected = abs(opt.rawValue - state.snowIntensity) < 0.15
                            Button(action: { state.snowIntensity = opt.rawValue }) {
                                Text(snowOptionTitle(opt))
                                    .font(monoFont(size: 8.5, weight: isSelected ? .bold : .regular))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? (isDark ? Color(hex: 0x89C4E1).opacity(0.3) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                                    .foregroundColor(isSelected ? (isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                                    .cornerRadius(3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Snow layer mode row
                HStack(spacing: 6) {
                    Image(systemName: "square.2.layers.3d")
                        .font(.system(size: 9.5))
                        .foregroundColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))

                    Text(isEn ? "LAYER" : "CAPA")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach(SnowLayerMode.allCases) { mode in
                            let isSelected = state.snowLayerMode == mode
                            Button(action: { state.snowLayerMode = mode }) {
                                Text(mode.displayName(in: state.language))
                                    .font(monoFont(size: 8.5, weight: isSelected ? .bold : .regular))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? (isDark ? Color(hex: 0x89C4E1).opacity(0.3) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                                    .foregroundColor(isSelected ? (isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                                    .cornerRadius(3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Snow style row (Flakes 3D/PX + Base 3D/PX)
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9.5))
                        .foregroundColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))

                    Text(isEn ? "STYLE" : "ESTILO")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer(minLength: 4)

                    HStack(spacing: 6) {
                        // Flakes group
                        HStack(spacing: 3) {
                            Text(isEn ? "Flakes" : "Copos")
                                .font(monoFont(size: 7.5, weight: .medium))
                                .foregroundColor(secondaryTextColor)

                            snowStyleButton(title: "3D", isSelected: state.snowflakesStyle == .colorful) {
                                state.snowflakesStyle = .colorful
                            }
                            snowStyleButton(title: "PX", isSelected: state.snowflakesStyle == .pixelArt) {
                                state.snowflakesStyle = .pixelArt
                            }
                        }

                        // Base group
                        HStack(spacing: 3) {
                            Text("Base")
                                .font(monoFont(size: 7.5, weight: .medium))
                                .foregroundColor(secondaryTextColor)

                            snowStyleButton(title: "3D", isSelected: state.snowbankStyle == .colorful) {
                                state.snowbankStyle = .colorful
                            }
                            snowStyleButton(title: "PX", isSelected: state.snowbankStyle == .pixelArt) {
                                state.snowbankStyle = .pixelArt
                            }
                        }
                    }
                }

                // Snow elves row (Off / 1 / Crew + 3D / PX)
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 9.5))
                        .foregroundColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))

                    Text(isEn ? "ELVES" : "DUENDES")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer(minLength: 4)

                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            ForEach(SnowElvesMode.allCases) { mode in
                                let isSelected = state.snowElvesMode == mode
                                Button(action: { state.snowElvesMode = mode }) {
                                    Text(mode.displayName(in: state.language))
                                        .font(monoFont(size: 8, weight: isSelected ? .bold : .regular))
                                        .padding(.horizontal, 4.5)
                                        .padding(.vertical, 2)
                                        .background(isSelected ? (isDark ? Color(hex: 0x89C4E1).opacity(0.3) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                                        .foregroundColor(isSelected ? (isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                                        .cornerRadius(3)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if state.snowElvesMode != .off {
                            HStack(spacing: 3) {
                                snowStyleButton(title: "3D", isSelected: state.snowElvesStyle == .colorful) {
                                    state.snowElvesStyle = .colorful
                                }
                                snowStyleButton(title: "PX", isSelected: state.snowElvesStyle == .pixelArt) {
                                    state.snowElvesStyle = .pixelArt
                                }
                            }
                        }
                    }
                }
            }

            // Winter wind row
            if state.isSnowing || audio.isWindPlaying {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.system(size: 9.5))
                        .foregroundColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))

                    Text(isEn ? "WIND" : "VIENTO")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    if !audio.isWindPlaying {
                        Spacer()
                    }

                    Button(action: { audio.toggleWind() }) {
                        Text(audio.isWindPlaying ? (isEn ? "ON" : "ACTIVO") : (isEn ? "OFF" : "NO"))
                            .font(monoFont(size: 8.5, weight: audio.isWindPlaying ? .bold : .regular))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(audio.isWindPlaying ? (isDark ? Color(hex: 0x89C4E1).opacity(0.3) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(audio.isWindPlaying ? (isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(3)
                    }
                    .buttonStyle(.plain)

                    if audio.isWindPlaying {
                        Slider(value: $audio.windVolume, in: 0...1)
                            .accentColor(isDark ? Color(hex: 0x89C4E1) : Color(hex: 0x1D3B2E))
                    }
                }
            }

            // Lights pattern & color rows
            if state.showTopLights {
                // Pattern row
                HStack(spacing: 6) {
                    LightsShape()
                        .stroke(lineWidth: 1)
                        .frame(width: 12, height: 10)
                        .foregroundColor(goldBrassColor)

                    Text(isEn ? "PATTERN" : "PATRÓN")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach(LightsPattern.allCases) { pat in
                            let isSelected = state.lightsPattern == pat
                            Button(action: { state.lightsPattern = pat }) {
                                Text(lightsPatternTitle(pat))
                                    .font(monoFont(size: 8, weight: isSelected ? .bold : .regular))
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? (isDark ? goldBrassColor.opacity(0.3) : Color(hex: 0xD4AF37)) : surfaceCardColor)
                                    .foregroundColor(isSelected ? (isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E)) : secondaryTextColor)
                                    .cornerRadius(3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Color palette row
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 9.5))
                        .foregroundColor(goldBrassColor)

                    Text("COLOR")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach(LightsPalette.allCases) { pal in
                            let isSelected = state.lightsPalette == pal
                            Button(action: { state.lightsPalette = pal }) {
                                VStack(spacing: 1.5) {
                                    HStack(spacing: 2) {
                                        ForEach(0..<3, id: \.self) { idx in
                                            Circle()
                                                .fill(palettePreviewColors(pal)[idx])
                                                .frame(width: 4.5, height: 4.5)
                                        }
                                    }
                                    Text(pal.shortName(in: state.language))
                                        .font(monoFont(size: 7, weight: isSelected ? .bold : .regular))
                                        .foregroundColor(isSelected ? (isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E)) : secondaryTextColor)
                                }
                                .padding(.horizontal, 3.5)
                                .padding(.vertical, 2.5)
                                .background(
                                    isSelected
                                        ? (isDark ? goldBrassColor.opacity(0.3) : Color(hex: 0xD4AF37))
                                        : surfaceCardColor
                                )
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(isSelected ? goldBrassColor : Color.clear, lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .help(pal.displayName(in: state.language))
                        }
                    }
                }

                // Lights style row (3D / Pixel Art)
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 9.5))
                        .foregroundColor(goldBrassColor)

                    Text(isEn ? "STYLE" : "ESTILO")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Spacer()

                    HStack(spacing: 3) {
                        Button(action: { state.lightsStyle = .colorful }) {
                            Text("3D")
                                .font(monoFont(size: 8.5, weight: state.lightsStyle == .colorful ? .bold : .regular))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(state.lightsStyle == .colorful ? (isDark ? goldBrassColor.opacity(0.3) : Color(hex: 0xD4AF37)) : surfaceCardColor)
                                .foregroundColor(state.lightsStyle == .colorful ? (isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E)) : secondaryTextColor)
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)

                        Button(action: { state.lightsStyle = .pixelArt }) {
                            Text("Pixel Art")
                                .font(monoFont(size: 8.5, weight: state.lightsStyle == .pixelArt ? .bold : .regular))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(state.lightsStyle == .pixelArt ? (isDark ? goldBrassColor.opacity(0.3) : Color(hex: 0xD4AF37)) : surfaceCardColor)
                                .foregroundColor(state.lightsStyle == .pixelArt ? (isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E)) : secondaryTextColor)
                                .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Fireplace volume row
            if audio.isFireplacePlaying {
                HStack(spacing: 6) {
                    FlameShape()
                        .fill()
                        .frame(width: 9, height: 11)
                        .foregroundColor(accentRedColor)

                    Text(isEn ? "HEARTH" : "FUEGO")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .foregroundColor(secondaryTextColor)

                    Slider(value: $audio.fireplaceVolume, in: 0...1)
                        .accentColor(accentRedColor)
                }
            }
        }
        .padding(8)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    private func snowOptionTitle(_ opt: SnowIntensityOption) -> String {
        switch opt {
        case .light: return isEn ? "Light" : "Suave"
        case .medium: return isEn ? "Medium" : "Media"
        case .heavy: return isEn ? "Blizzard" : "Nevada"
        }
    }

    private func lightsPatternTitle(_ pat: LightsPattern) -> String {
        switch pat {
        case .twinkle: return isEn ? "Twinkle" : "Parpadeo"
        case .wave: return isEn ? "Wave" : "Ola"
        case .warmSteady: return isEn ? "Steady" : "Fija"
        case .rhythm: return isEn ? "Rhythm" : "Ritmo"
        }
    }

    private func palettePreviewColors(_ pal: LightsPalette) -> [Color] {
        switch pal {
        case .classic:
            return [Color(hex: 0xFF3B30), Color(hex: 0xFFD60A), Color(hex: 0x30D158)]
        case .warm:
            return [Color(hex: 0xFFC752), Color(hex: 0xFFDB85), Color(hex: 0xFFF2CC)]
        case .candyCane:
            return [Color(hex: 0xF52433), Color(hex: 0xFAFAFF), Color(hex: 0xFF4D5C)]
        case .nordicIce:
            return [Color(hex: 0x339EFA), Color(hex: 0x7AE0FF), Color(hex: 0xEBFAFF)]
        case .pineGold:
            return [Color(hex: 0x24AD5C), Color(hex: 0xF2C73D), Color(hex: 0xFFEBB3)]
        }
    }

    @ViewBuilder
    private func snowStyleButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(monoFont(size: 8, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 4.5)
                .padding(.vertical, 2)
                .background(isSelected ? (isDark ? Color(hex: 0x89C4E1).opacity(0.3) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                .foregroundColor(isSelected ? (isDark ? Color(hex: 0x89C4E1) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Santa Sleigh Section
    private var santaSleighSection: some View {
        HStack(spacing: 6) {
            // Left: Sleigh Icon + SANTA label
            HStack(spacing: 4) {
                SleighShape()
                    .stroke(lineWidth: 1.2)
                    .frame(width: 15, height: 11)
                    .foregroundColor(goldBrassColor)

                Text("SANTA")
                    .font(monoFont(size: 8.5, weight: .bold))
                    .foregroundColor(secondaryTextColor)
            }

            Spacer(minLength: 4)

            // Center: Frequency segmented buttons
            HStack(spacing: 3) {
                ForEach(SantaFrequency.allCases) { freq in
                    let isSelected = state.santaFrequency == freq
                    Button(action: { state.santaFrequency = freq }) {
                        Text(santaFreqTitle(freq))
                            .font(monoFont(size: 8, weight: isSelected ? .bold : .regular))
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 2)
                            .background(
                                isSelected
                                    ? (isDark ? goldBrassColor.opacity(0.3) : Color(hex: 0xD4AF37))
                                    : surfaceCardColor
                            )
                            .foregroundColor(
                                isSelected
                                    ? (isDark ? Color(hex: 0xE2C15A) : Color(hex: 0x1D3B2E))
                                    : secondaryTextColor
                            )
                            .cornerRadius(3)
                    }
                    .buttonStyle(.plain)
                    .help(santaFreqHelp(freq))
                }
            }

            Spacer(minLength: 4)

            // Right: Sound toggle + Flight invocation button
            HStack(spacing: 3) {
                Button(action: {
                    state.santaSoundEnabled.toggle()
                }) {
                    Image(systemName: state.santaSoundEnabled ? "bell.fill" : "bell.slash")
                        .font(.system(size: 9.5))
                        .foregroundColor(state.santaSoundEnabled ? goldBrassColor : secondaryTextColor.opacity(0.65))
                        .frame(width: 20, height: 18)
                        .background(surfaceCardColor)
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(surfaceCardBorder, lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help(isEn ? "Sleigh bells sound" : "Sonido de cascabeles")

                Button(action: {
                    ScreenEffectsManager.shared.triggerSantaFlightNow()
                }) {
                    Text(isEn ? "Fly" : "Volar")
                        .font(monoFont(size: 8.5, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            isDark
                                ? accentRedColor.opacity(0.35)
                                : accentRedColor.opacity(0.18)
                        )
                        .foregroundColor(
                            isDark
                                ? Color(hex: 0xF4EFE6)
                                : accentRedColor
                        )
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(accentRedColor.opacity(isDark ? 0.6 : 0.4), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help(isEn ? "Invoke Santa's flight now" : "Invocar vuelo de Santa ahora")
            }
        }
        .padding(8)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    private func santaFreqTitle(_ freq: SantaFrequency) -> String {
        switch freq {
        case .off:
            return isEn ? "Off" : "No"
        case .occasional:
            return isEn ? "Occ." : "Ocas."
        case .frequent:
            return isEn ? "Often" : "Frec."
        }
    }

    private func santaFreqHelp(_ freq: SantaFrequency) -> String {
        switch freq {
        case .off:
            return isEn ? "Santa flights disabled" : "Vuelos de Santa desactivados"
        case .occasional:
            return isEn ? "Occasional flights" : "Vuelos ocasionales"
        case .frequent:
            return isEn ? "Frequent flights" : "Vuelos frecuentes"
        }
    }

    // MARK: - Settings View Content
    private var settingsContentView: some View {
        VStack(spacing: 12) {
            // Character selector (5 hand-drawn minimalist vector shapes)
            characterSelectorSection

            // Style & Spin selectors
            styleAndSpinSection

            // Appearance: Typography & Theme
            appearanceSection

            // MP3 Custom Folder
            folderSection

            // Countdown in menu bar toggle
            Toggle(
                isEn ? "Show countdown in menu bar" : "Mostrar días en barra superior",
                isOn: $state.showCountdownInMenuBar
            )
            .font(monoFont(size: 10))
            .foregroundColor(primaryTextColor)
            .toggleStyle(.checkbox)

            // Launch at login toggle
            Toggle(
                isEn ? "Launch Noël at login" : "Iniciar Noël al encender la Mac",
                isOn: $state.launchAtLogin
            )
            .font(monoFont(size: 10))
            .foregroundColor(primaryTextColor)
            .toggleStyle(.checkbox)
        }
    }

    // MARK: - Character Selector Section
    private var characterSelectorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isEn ? "MENU BAR CHARACTER" : "PERSONAJE EN BARRA")
                .font(monoFont(size: 9.5, weight: .bold))
                .foregroundColor(secondaryTextColor)

            HStack(spacing: 5) {
                ForEach(CharacterType.allCases) { char in
                    let isSelected = state.selectedCharacter == char
                    Button(action: { state.selectedCharacter = char }) {
                        VStack(spacing: 4) {
                            Group {
                                switch char {
                                case .tree:
                                    PineTreeShape()
                                        .fill(isSelected ? primaryTextColor : secondaryTextColor)
                                        .frame(width: 18, height: 18)
                                case .snowman:
                                    SnowmanShape()
                                        .fill(isSelected ? primaryTextColor : secondaryTextColor)
                                        .frame(width: 18, height: 18)
                                case .reindeer:
                                    ReindeerShape()
                                        .stroke(isSelected ? primaryTextColor : secondaryTextColor, lineWidth: 1.2)
                                        .frame(width: 18, height: 18)
                                case .santa:
                                    SantaHatShape()
                                        .fill(isSelected ? primaryTextColor : secondaryTextColor)
                                        .frame(width: 18, height: 18)
                                case .hotCocoa:
                                    CocoaCupShape()
                                        .stroke(isSelected ? primaryTextColor : secondaryTextColor, lineWidth: 1.2)
                                        .frame(width: 18, height: 18)
                                }
                            }

                            Text(characterLabel(char))
                                .font(monoFont(size: 8.5, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? primaryTextColor : secondaryTextColor)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSelected ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.12) : Color(hex: 0xEDE3D2)) : surfaceCardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? (isDark ? goldBrassColor : accentRedColor) : surfaceCardBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func characterLabel(_ char: CharacterType) -> String {
        switch char {
        case .tree: return isEn ? "PINE" : "PINO"
        case .snowman: return isEn ? "SNOW" : "MUÑECO"
        case .reindeer: return isEn ? "DEER" : "RENO"
        case .santa: return isEn ? "SANTA" : "SANTA"
        case .hotCocoa: return isEn ? "COCOA" : "CHOCO"
        }
    }

    // MARK: - Style & Spin Section
    private var styleAndSpinSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Style
            HStack {
                Text(isEn ? "STYLE" : "ESTILO")
                    .font(monoFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.iconStyle = .colorful }) {
                        Text(isEn ? "3D Color" : "Color 3D")
                            .font(monoFont(size: 9, weight: state.iconStyle == .colorful ? .bold : .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(state.iconStyle == .colorful ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.iconStyle == .colorful ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.iconStyle = .pixelArt }) {
                        Text("Pixel Art")
                            .font(monoFont(size: 9, weight: state.iconStyle == .pixelArt ? .bold : .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(state.iconStyle == .pixelArt ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.iconStyle == .pixelArt ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Spin animation
            HStack {
                Text(isEn ? "SPIN" : "GIRO")
                    .font(monoFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.animationMode = .always }) {
                        Text(isEn ? "Always" : "Siempre")
                            .font(monoFont(size: 9, weight: state.animationMode == .always ? .bold : .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(state.animationMode == .always ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.animationMode == .always ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.animationMode = .onlyWhenPlaying }) {
                        Text(isEn ? "With Music" : "Con Música")
                            .font(monoFont(size: 9, weight: state.animationMode == .onlyWhenPlaying ? .bold : .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(state.animationMode == .onlyWhenPlaying ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.animationMode == .onlyWhenPlaying ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Appearance Section (Typography & Theme)
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Font selector
            HStack {
                Text(isEn ? "FONT" : "FUENTE")
                    .font(monoFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.fontStyle = .typewriter }) {
                        Text("Typewriter")
                            .font(Font.custom("American Typewriter", size: 10.5))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.fontStyle == .typewriter ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.fontStyle == .typewriter ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.fontStyle = .optima }) {
                        Text("Optima")
                            .font(Font.custom("Optima", size: 11))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.fontStyle == .optima ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.fontStyle == .optima ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Theme selector
            HStack {
                Text(isEn ? "THEME" : "TEMA")
                    .font(monoFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.themeMode = .dark }) {
                        Text(isEn ? "Pino" : "Pino")
                            .font(monoFont(size: 9, weight: state.themeMode == .dark ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.themeMode == .dark ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.themeMode == .dark ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.themeMode = .light }) {
                        Text(isEn ? "Crema" : "Crema")
                            .font(monoFont(size: 9, weight: state.themeMode == .light ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.themeMode == .light ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.themeMode == .light ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.themeMode = .system }) {
                        Text("Auto")
                            .font(monoFont(size: 9, weight: state.themeMode == .system ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.themeMode == .system ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.themeMode == .system ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Displays selector
            HStack {
                Text(isEn ? "DISPLAYS" : "PANTALLAS")
                    .font(monoFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.screenTargetMode = .allScreens }) {
                        Text(isEn ? "All" : "Todas")
                            .font(monoFont(size: 9, weight: state.screenTargetMode == .allScreens ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.screenTargetMode == .allScreens ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.screenTargetMode == .allScreens ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button(action: { state.screenTargetMode = .mainOnly }) {
                        Text(isEn ? "Main Only" : "Principal")
                            .font(monoFont(size: 9, weight: state.screenTargetMode == .mainOnly ? .bold : .regular))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(state.screenTargetMode == .mainOnly ? (isDark ? Color(hex: 0xF4EFE6).opacity(0.15) : Color(hex: 0x1D3B2E)) : surfaceCardColor)
                            .foregroundColor(state.screenTargetMode == .mainOnly ? (isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4)) : secondaryTextColor)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(8)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Folder Section
    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEn
                     ? "\(audio.builtInTrackCount) built-in · \(audio.customTrackCount) local"
                     : "\(audio.builtInTrackCount) integradas · \(audio.customTrackCount) locales")
                    .font(monoFont(size: 9.5))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                Button(action: { audio.reloadTracks() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                        Text(isEn ? "Reload" : "Recargar")
                    }
                    .font(monoFont(size: 9.5))
                    .foregroundColor(primaryTextColor)
                }
                .buttonStyle(.plain)
            }

            if let folderPath = state.customMusicFolderPath, !folderPath.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9))
                        .foregroundColor(goldBrassColor)
                    Text(URL(fileURLWithPath: folderPath).lastPathComponent)
                        .font(monoFont(size: 9.5))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(primaryTextColor)
                    Spacer()
                    Button(action: { audio.clearCustomFolder() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .help(isEn ? "Remove custom folder" : "Quitar carpeta personalizada")
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(surfaceCardColor)
                .cornerRadius(4)
            }

            Button(action: { audio.chooseMusicFolder() }) {
                HStack(spacing: 5) {
                    Image(systemName: "folder.badge.plus")
                    Text(isEn ? "Choose MP3 Folder..." : "Elegir carpeta MP3...")
                }
                .font(monoFont(size: 10))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(surfaceCardColor)
                .foregroundColor(primaryTextColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(surfaceCardBorder, lineWidth: 1)
                )
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(surfaceCardColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(surfaceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text(isEn ? "R-CLICK: PLAY · OPT+CLICK: HIDE" : "CLIC DER: PLAY · OPT+CLIC: OCULTAR")
                .font(monoFont(size: 9))
                .foregroundColor(secondaryTextColor)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text(isEn ? "QUIT" : "SALIR")
                    .font(monoFont(size: 9.5, weight: .bold))
                    .foregroundColor(accentRedColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }
}

// MARK: - Ambience Pill Button
private struct AmbiencePillButton<IconContent: View>: View {
    let title: String
    let isActive: Bool
    let activeTint: Color
    let activeTextColor: Color
    let isDark: Bool
    let monoFont: Font
    @ViewBuilder let icon: () -> IconContent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                icon()
                Text(title)
                    .font(monoFont)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                Group {
                    if isActive {
                        if isDark {
                            activeTint.opacity(0.22)
                        } else {
                            activeTint
                        }
                    } else {
                        if isDark {
                            Color(hex: 0xF4EFE6).opacity(0.06)
                        } else {
                            Color(hex: 0xE8DEC8).opacity(0.6)
                        }
                    }
                }
            )
            .foregroundColor(
                isActive
                    ? activeTextColor
                    : (isDark ? Color(hex: 0xF4EFE6).opacity(0.58) : Color(hex: 0x6E6252))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        isActive
                            ? (isDark ? activeTint.opacity(0.8) : activeTint.opacity(0.4))
                            : (isDark ? Color(hex: 0xF4EFE6).opacity(0.12) : Color(hex: 0xCBBBA0)),
                        lineWidth: 1
                    )
            )
            .cornerRadius(7)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vinyl Record View
private struct VinylRecordView: View {
    let isDark: Bool
    let accentColor: Color
    let goldColor: Color

    var body: some View {
        ZStack {
            // Base dark disc
            Circle()
                .fill(Color(hex: 0x141A17))

            // Concentric grooves
            Circle()
                .stroke(Color.black.opacity(0.65), lineWidth: 1.0)
                .frame(width: 48, height: 48)

            Circle()
                .stroke(Color.white.opacity(isDark ? 0.09 : 0.14), lineWidth: 0.6)
                .frame(width: 40, height: 40)

            Circle()
                .stroke(Color.black.opacity(0.65), lineWidth: 1.0)
                .frame(width: 32, height: 32)

            // Red center label
            Circle()
                .fill(accentColor)
                .frame(width: 24, height: 24)

            // Brass gold ring
            Circle()
                .stroke(goldColor, lineWidth: 0.9)
                .frame(width: 20, height: 20)

            // Center spindle hole
            Circle()
                .fill(isDark ? Color(hex: 0xF4EFE6) : Color(hex: 0xF6F0E4))
                .frame(width: 5, height: 5)
        }
    }
}

// MARK: - Theme Divider
private struct ThemeDivider: View {
    let isDark: Bool

    var body: some View {
        if isDark {
            Rectangle()
                .fill(Color(hex: 0xF4EFE6).opacity(0.12))
                .frame(height: 1)
        } else {
            LineDashed()
                .stroke(Color(hex: 0xCBBBA0), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(height: 1)
        }
    }
}

private struct LineDashed: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Handcrafted Vector Shapes (Zero Emojis)

struct SnowflakeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) * 0.46

        for i in 0..<3 {
            let angle = CGFloat(i) * (.pi / 3.0)
            let dx = cos(angle) * r
            let dy = sin(angle) * r
            p.move(to: CGPoint(x: cx - dx, y: cy - dy))
            p.addLine(to: CGPoint(x: cx + dx, y: cy + dy))

            for sign in [-1.0, 1.0] {
                let branchR = r * 0.28
                let bAngle1 = angle + CGFloat(sign) * (.pi / 4.0)
                let bAngle2 = angle - CGFloat(sign) * (.pi / 4.0)
                let notchDist = r * 0.65
                let nx = cx + CGFloat(sign) * cos(angle) * notchDist
                let ny = cy + CGFloat(sign) * sin(angle) * notchDist
                p.move(to: CGPoint(x: nx + cos(bAngle1) * branchR, y: ny + sin(bAngle1) * branchR))
                p.addLine(to: CGPoint(x: nx, y: ny))
                p.addLine(to: CGPoint(x: nx + cos(bAngle2) * branchR, y: ny + sin(bAngle2) * branchR))
            }
        }
        return p
    }
}

struct LightsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.25))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.25),
            control: CGPoint(x: rect.midX, y: rect.minY + h * 0.55)
        )

        let xCoords = [w * 0.22, w * 0.5, w * 0.78]
        let yOffsets = [h * 0.45, h * 0.55, h * 0.45]
        let bulbR: CGFloat = min(w, h) * 0.2

        for i in 0..<3 {
            let bx = rect.minX + xCoords[i]
            let by = rect.minY + yOffsets[i]
            let bulbRect = CGRect(x: bx - bulbR, y: by, width: bulbR * 2, height: bulbR * 2.2)
            p.addEllipse(in: bulbRect)
        }
        return p
    }
}

struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let mx = rect.midX
        let by = rect.maxY

        p.move(to: CGPoint(x: mx, y: rect.minY + h * 0.05))
        p.addCurve(
            to: CGPoint(x: mx + w * 0.45, y: by - h * 0.3),
            control1: CGPoint(x: mx + w * 0.35, y: rect.minY + h * 0.25),
            control2: CGPoint(x: mx + w * 0.55, y: by - h * 0.55)
        )
        p.addCurve(
            to: CGPoint(x: mx, y: by),
            control1: CGPoint(x: mx + w * 0.35, y: by),
            control2: CGPoint(x: mx + w * 0.1, y: by)
        )
        p.addCurve(
            to: CGPoint(x: mx - w * 0.45, y: by - h * 0.3),
            control1: CGPoint(x: mx - w * 0.1, y: by),
            control2: CGPoint(x: mx - w * 0.35, y: by)
        )
        p.addCurve(
            to: CGPoint(x: mx, y: rect.minY + h * 0.05),
            control1: CGPoint(x: mx - w * 0.55, y: by - h * 0.55),
            control2: CGPoint(x: mx - w * 0.35, y: rect.minY + h * 0.25)
        )
        p.closeSubpath()
        return p
    }
}

struct SleighShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // 1. Runner (patín inferior con rizo frontal)
        p.move(to: CGPoint(x: rect.minX + w * 0.05, y: rect.maxY - h * 0.12))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.78, y: rect.maxY - h * 0.12))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.96, y: rect.minY + h * 0.62),
            control: CGPoint(x: rect.minX + w * 0.94, y: rect.maxY - h * 0.12)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.88, y: rect.minY + h * 0.68),
            control: CGPoint(x: rect.minX + w * 0.96, y: rect.minY + h * 0.72)
        )

        // 2. Struts (montantes de apoyo)
        p.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - h * 0.12))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.68))

        p.move(to: CGPoint(x: rect.minX + w * 0.65, y: rect.maxY - h * 0.12))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.65, y: rect.minY + h * 0.68))

        // 3. Body / Carriage (cuerpo del trineo con respaldo alto y frente curvo)
        p.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.20))
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.68),
            control1: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.52),
            control2: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.68)
        )
        p.addLine(to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.68))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.85, y: rect.minY + h * 0.32),
            control: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.62)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.40),
            control: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.32)
        )

        return p
    }
}

struct PineTreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mx = rect.midX
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: mx, y: rect.minY + h * 0.05))
        p.addLine(to: CGPoint(x: mx + w * 0.25, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: mx + w * 0.15, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: mx + w * 0.35, y: rect.minY + h * 0.62))
        p.addLine(to: CGPoint(x: mx + w * 0.22, y: rect.minY + h * 0.62))
        p.addLine(to: CGPoint(x: mx + w * 0.45, y: rect.minY + h * 0.88))
        p.addLine(to: CGPoint(x: mx + w * 0.09, y: rect.minY + h * 0.88))
        p.addLine(to: CGPoint(x: mx + w * 0.09, y: rect.maxY))
        p.addLine(to: CGPoint(x: mx - w * 0.09, y: rect.maxY))
        p.addLine(to: CGPoint(x: mx - w * 0.09, y: rect.minY + h * 0.88))
        p.addLine(to: CGPoint(x: mx - w * 0.45, y: rect.minY + h * 0.88))
        p.addLine(to: CGPoint(x: mx - w * 0.22, y: rect.minY + h * 0.62))
        p.addLine(to: CGPoint(x: mx - w * 0.35, y: rect.minY + h * 0.62))
        p.addLine(to: CGPoint(x: mx - w * 0.15, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: mx - w * 0.25, y: rect.minY + h * 0.35))
        p.closeSubpath()
        return p
    }
}

struct SnowmanShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mx = rect.midX
        let w = rect.width
        let h = rect.height

        let bodyR = min(w, h) * 0.27
        p.addEllipse(in: CGRect(x: mx - bodyR, y: rect.maxY - bodyR * 2.05, width: bodyR * 2, height: bodyR * 2))

        let headR = min(w, h) * 0.20
        p.addEllipse(in: CGRect(x: mx - headR, y: rect.minY + h * 0.22, width: headR * 2, height: headR * 2))

        let brimW = headR * 2.3
        p.addRect(CGRect(x: mx - brimW * 0.5, y: rect.minY + h * 0.19, width: brimW, height: h * 0.06))

        let topW = headR * 1.4
        p.addRect(CGRect(x: mx - topW * 0.5, y: rect.minY + h * 0.05, width: topW, height: h * 0.14))

        return p
    }
}

struct ReindeerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mx = rect.midX
        let w = rect.width
        let h = rect.height

        let headRect = CGRect(x: mx - w * 0.28, y: rect.minY + h * 0.38, width: w * 0.56, height: h * 0.58)
        p.addEllipse(in: headRect)

        p.move(to: CGPoint(x: mx - w * 0.15, y: rect.minY + h * 0.42))
        p.addLine(to: CGPoint(x: mx - w * 0.42, y: rect.minY + h * 0.12))
        p.move(to: CGPoint(x: mx - w * 0.28, y: rect.minY + h * 0.28))
        p.addLine(to: CGPoint(x: mx - w * 0.18, y: rect.minY + h * 0.16))
        p.move(to: CGPoint(x: mx - w * 0.35, y: rect.minY + h * 0.20))
        p.addLine(to: CGPoint(x: mx - w * 0.46, y: rect.minY + h * 0.25))

        p.move(to: CGPoint(x: mx + w * 0.15, y: rect.minY + h * 0.42))
        p.addLine(to: CGPoint(x: mx + w * 0.42, y: rect.minY + h * 0.12))
        p.move(to: CGPoint(x: mx + w * 0.28, y: rect.minY + h * 0.28))
        p.addLine(to: CGPoint(x: mx + w * 0.18, y: rect.minY + h * 0.16))
        p.move(to: CGPoint(x: mx + w * 0.35, y: rect.minY + h * 0.20))
        p.addLine(to: CGPoint(x: mx + w * 0.46, y: rect.minY + h * 0.25))

        let noseR = w * 0.10
        p.addEllipse(in: CGRect(x: mx - noseR, y: rect.minY + h * 0.76, width: noseR * 2, height: noseR * 2))

        return p
    }
}

struct SantaHatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: rect.minX + w * 0.15, y: rect.maxY - h * 0.22))
        p.addCurve(
            to: CGPoint(x: rect.maxX - w * 0.18, y: rect.minY + h * 0.32),
            control1: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.1),
            control2: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + h * 0.05)
        )
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.15, y: rect.maxY - h * 0.22))
        p.closeSubpath()

        let brimRect = CGRect(x: rect.minX + w * 0.08, y: rect.maxY - h * 0.26, width: w * 0.84, height: h * 0.18)
        p.addRoundedRect(in: brimRect, cornerSize: CGSize(width: h * 0.09, height: h * 0.09))

        let pomR = min(w, h) * 0.14
        let pomRect = CGRect(x: rect.maxX - w * 0.28, y: rect.minY + h * 0.25, width: pomR * 2, height: pomR * 2)
        p.addEllipse(in: pomRect)

        return p
    }
}

struct CocoaCupShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        let mugRect = CGRect(x: rect.minX + w * 0.18, y: rect.minY + h * 0.40, width: w * 0.52, height: h * 0.52)
        p.addRoundedRect(in: mugRect, cornerSize: CGSize(width: w * 0.08, height: w * 0.08))

        p.move(to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.48))
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.82),
            control1: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.50),
            control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.80)
        )

        p.move(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.34))
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.36, y: rect.minY + h * 0.08),
            control1: CGPoint(x: rect.minX + w * 0.24, y: rect.minY + h * 0.24),
            control2: CGPoint(x: rect.minX + w * 0.44, y: rect.minY + h * 0.18)
        )

        p.move(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.34))
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.56, y: rect.minY + h * 0.08),
            control1: CGPoint(x: rect.minX + w * 0.44, y: rect.minY + h * 0.24),
            control2: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.18)
        )

        return p
    }
}

// MARK: - Color Hex Initializer
private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
