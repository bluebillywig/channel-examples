import SwiftUI
import BBNativePlayerKit
import BBNativePlayerKit_SwiftUI
import BBChannelSwiftUI
import os.log

private let log = Logger(subsystem: "com.bluebillywig.bbchannel", category: "BBChannelWithPlayer")

/// Composite view combining a BB Channel WebView with a native inline player.
///
/// Equivalent to `BBChannelWithPlayer` in the React Native SDK.
///
/// Usage:
/// ```swift
/// @StateObject private var playerVM = BBChannelWithPlayerViewModel()
///
/// BBChannelWithPlayerView(
///     channelUrl: "https://demo.bbvms.com/ch/123.json",
///     viewModel: playerVM,
///     callbacks: BBChannelCallbacks(onReady: { print("Ready") })
/// )
/// ```
public struct BBChannelWithPlayerView: View {
    let channelUrl: String
    let options: BBChannelOptions
    let callbacks: BBChannelCallbacks
    let showBackArrow: Bool
    let playerAspectRatio: CGFloat

    @ObservedObject var viewModel: BBChannelWithPlayerViewModel

    public init(
        channelUrl: String,
        options: BBChannelOptions = BBChannelOptions(),
        viewModel: BBChannelWithPlayerViewModel,
        callbacks: BBChannelCallbacks = BBChannelCallbacks(),
        showBackArrow: Bool = true,
        playerAspectRatio: CGFloat = 16.0 / 9.0
    ) {
        self.channelUrl = channelUrl
        self.options = options
        self.viewModel = viewModel
        self.callbacks = callbacks
        self.showBackArrow = showBackArrow
        self.playerAspectRatio = playerAspectRatio
    }

    @State private var containerWidth: CGFloat = 0
    @State private var deferredHideTask: DispatchWorkItem?
    @State private var lastKnownClipId: String?

    // Native player mode is always enabled in this composite view
    private var mergedOptions: BBChannelOptions {
        var opts = options
        opts.nativePlayerMode = true
        return opts
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            backArrowHeader()
            inlinePlayerSection()
            channelWebView()
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { containerWidth = geo.size.width }
                    .onChange(of: geo.size.width) { containerWidth = $1 }
            }
        )
        .onDisappear {
            deferredHideTask?.cancel()
            viewModel.destroyPlayer()
        }
        // clipData observation stays on parent — it fires infrequently (only on clip change)
        // and doesn't cause the re-render cascade that continuous state props do.
        .onChange(of: viewModel.nativePlayerState.clipData?.id) { oldId, newId in
            guard let id = newId, id != oldId else { return }
            viewModel.channelVM.updateDetailPageEntity(id)
            // Update header title on auto-advance (clipData changes but handleMediaPlay doesn't fire)
            if let clip = viewModel.nativePlayerState.clipData {
                viewModel.currentMedia?.title = clip.title
            }
        }
    }

    // MARK: - Channel WebView

    @ViewBuilder
    private func channelWebView() -> some View {
        BBChannelView(
            channelUrl: channelUrl,
            options: mergedOptions,
            viewModel: viewModel.channelVM,
            callbacks: wrapCallbacks()
        )
    }

    // MARK: - Back Arrow Header

    @ViewBuilder
    private func backArrowHeader() -> some View {
        if showBackArrow && viewModel.isPlayerVisible, let media = viewModel.currentMedia {
            let bgColor = Color(hex: media.backgroundColor ?? "#000")
            let bgImageUrl = media.blurredThumbnailUrl ?? media.thumbnailUrl
            let showBgImage = media.showThumbnailAsBackground == true && bgImageUrl != nil

            // RN: flexDirection:'row', alignItems:'center', paddingHorizontal:16, paddingVertical:12
            HStack {
                Button { handleDetailPageBack() } label: {
                    BackArrowShape()
                        .fill(.white)
                        .frame(width: 24, height: 16)
                        .padding(4)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                ZStack {
                    bgColor
                    if showBgImage, let url = bgImageUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                                .blur(radius: 15).scaleEffect(1.05)
                        } placeholder: { EmptyView() }
                        .clipped()
                        Color.black.opacity(0.55)
                    }
                }
            }
        }
    }

    // MARK: - Inline Player

    @ViewBuilder
    private func inlinePlayerSection() -> some View {
        if let media = viewModel.currentMedia {
            let isShown = viewModel.isPlayerVisible
            let computedHeight: CGFloat? = containerWidth > 0
                ? (containerWidth / playerAspectRatio).rounded()
                : nil

            // Isolate player in a separate view to prevent @Observable re-renders.
            // BBPlayerState is @Observable — any property change (phase, state, volume,
            // duration) would re-render the ENTIRE BBChannelWithPlayerView if accessed
            // in this body. StablePlayerWrapper avoids this by never reading state props.
            StablePlayerWrapper(
                jsonUrl: media.jsonUrl,
                autoPlay: media.autoplay ?? true,
                state: viewModel.nativePlayerState,
                context: buildContext(media),
                entityId: media.entityId ?? extractClipId(from: media.jsonUrl)
            )
            .frame(height: isShown ? computedHeight : 0)
            .clipped()
            .opacity(isShown ? 1 : 0)
            .allowsHitTesting(isShown)
            .background(Color.black)
        }
    }

    // MARK: - Handlers

    private func handleMediaPlay(_ media: BBMediaInfo) {
        // Overview/season pages — skip, let web handle
        if media.playerBlockId == "overviewPage" { return }

        let wasVisible = viewModel.isPlayerVisible
        let prevUrl = viewModel.currentMedia?.jsonUrl

        // Modal playback: inline placeholder taps (isInlinePlayer) or main page player block.
        // Detail page plays use inline player.
        let shouldModal = media.isInlinePlayer == true
        if shouldModal {
            // Pause inline player before modal — prevents double playback
            if viewModel.isPlayerVisible {
                viewModel.nativePlayerState.pause()
            }
            presentModalPlayer(media: media)
            return
        }

        viewModel.currentMedia = media
        viewModel.isPlayerVisible = true
        viewModel.playerState = .loading

        // Set GCKPlayerId so SDK's sessionStarted handler auto-casts this content.
        // Matches RN showCastPicker which writes jsonUrl to UserDefaults.
        UserDefaults.standard.set(media.jsonUrl, forKey: "com.bluebillywig.bbnativeplayerkit.GCKPlayerId")

        // Reuse existing player: load new content without destroying
        if prevUrl != media.jsonUrl {
            if let entityId = media.entityId {
                viewModel.nativePlayerState.loadClip(
                    id: entityId,
                    autoPlay: media.autoplay ?? true,
                    context: buildContext(media)
                )
            } else if let clipId = extractClipId(from: media.jsonUrl) {
                viewModel.nativePlayerState.loadClip(
                    id: clipId,
                    autoPlay: media.autoplay ?? true,
                    context: buildContext(media)
                )
            }
        } else if wasVisible {
            if media.autoplay != false {
                viewModel.nativePlayerState.play()
            }
        }
    }

    private func handleNavigationStateChange(_ state: BBNavigationState) {
        if viewModel.isPlayerVisible && state.pageType != .detailPage {
            // Defer hide: the WebView may briefly report a non-detailPage state
            // during detail-to-detail transitions. Cancel if detailPage arrives.
            deferredHideTask?.cancel()
            let task = DispatchWorkItem { [viewModel] in
                if viewModel.isPlayerVisible {
                    viewModel.hidePlayer()
                }
            }
            deferredHideTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        } else if state.pageType == .detailPage, deferredHideTask != nil {
            deferredHideTask?.cancel()
            deferredHideTask = nil
        }
    }

    private func handleDetailPageBack() {
        if viewModel.isPlayerVisible {
            viewModel.hidePlayer()
        }
        if viewModel.channelVM.canGoBack {
            viewModel.channelVM.goBack()
        } else {
            viewModel.channelVM.navigateTo("main")
        }
    }

    // MARK: - Helpers

    private func presentModalPlayer(media: BBMediaInfo) {
        guard let topVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var vc = topVC
        while let presented = vc.presentedViewController { vc = presented }

        let opts: [String: Any] = [
            "autoPlay": media.autoplay ?? true,
            "showBackArrow": true,
            "castMode": "auto",
        ]
        _ = BBNativePlayerKit.BBNativePlayer.createModalPlayerView(
            uiViewContoller: vc,
            jsonUrl: media.jsonUrl,
            options: opts
        )
    }

    private func buildContext(_ media: BBMediaInfo) -> [String: Any]? {
        guard let collectionId = media.contextCollectionId else { return nil }
        var ctx: [String: Any] = [
            "contextCollectionType": media.contextCollectionType ?? "MediaClipList",
            "contextCollectionId": collectionId,
        ]
        if let t = media.contextEntityType { ctx["contextEntityType"] = t }
        if let id = media.contextEntityId { ctx["contextEntityId"] = id }
        if let idx = media.listIndex { ctx["listIndex"] = idx }
        return ctx
    }

    private func extractClipId(from jsonUrl: String) -> String? {
        guard let range = jsonUrl.range(of: "/c/") else { return nil }
        let after = jsonUrl[range.upperBound...]
        guard let dotRange = after.range(of: ".json") else { return nil }
        return String(after[..<dotRange.lowerBound])
    }

    /// Wrap user callbacks + inject our handlers
    private func wrapCallbacks() -> BBChannelCallbacks {
        var wrapped = callbacks
        let origOnMediaPlay = callbacks.onMediaPlay
        wrapped.onMediaPlay = { media in
            handleMediaPlay(media)
            origOnMediaPlay?(media)
        }
        let origOnNavChange = callbacks.onNavigationStateChange
        wrapped.onNavigationStateChange = { state in
            handleNavigationStateChange(state)
            origOnNavChange?(state)
        }
        return wrapped
    }
}

/// Wrapper that isolates BBNativePlayer from parent @Observable re-renders.
/// Without this, every BBPlayerState property change (phase, state, volume, duration)
/// causes the entire BBChannelWithPlayerView body to re-evaluate because SwiftUI tracks
/// @Observable access. This wrapper's body only depends on jsonUrl/autoPlay (which don't
/// change during playback), so the player view stays stable.
private struct StablePlayerWrapper: View {
    let jsonUrl: String
    let autoPlay: Bool
    let state: BBNativePlayerKit_SwiftUI.BBPlayerState
    let context: [String: Any]?
    let entityId: String?

    var body: some View {
        BBNativePlayer(
            jsonUrl: jsonUrl,
            options: BBPlayerOptions(autoPlay: autoPlay, custom: ["castMode": "auto"]),
            state: state
        )
        .onChange(of: state.isReady) { _, isReady in
            // Re-load with playlist context for auto-advance
            guard isReady, let ctx = context else { return }
            if let entityId = entityId {
                state.loadClip(id: entityId, autoPlay: autoPlay, context: ctx)
            }
        }
    }
}

/// Back arrow shape matching the web channel's backArrow.svg and the RN SDK.
/// SVG viewBox: 0 0 31 20, path: M6.617 11.403H29.062C30.134...
private struct BackArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 31.0
        let sy = rect.height / 20.0
        var p = Path()
        // Arrow shaft
        p.move(to: CGPoint(x: 6.617 * sx, y: 11.403 * sy))
        p.addLine(to: CGPoint(x: 29.062 * sx, y: 11.403 * sy))
        // Top-right rounded end (approximated as arc)
        p.addQuadCurve(to: CGPoint(x: 29.062 * sx, y: 7.603 * sy),
                        control: CGPoint(x: 31 * sx, y: 9.503 * sy))
        p.addLine(to: CGPoint(x: 6.617 * sx, y: 7.603 * sy))
        // Top chevron
        p.addLine(to: CGPoint(x: 11.061 * sx, y: 3.246 * sy))
        p.addQuadCurve(to: CGPoint(x: 8.318 * sx, y: 0.557 * sy),
                        control: CGPoint(x: 11.818 * sx, y: 1.299 * sy))
        p.addQuadCurve(to: CGPoint(x: 0.568 * sx, y: 8.155 * sy),
                        control: CGPoint(x: 7.561 * sx, y: -0.186 * sy))
        // Center
        p.addQuadCurve(to: CGPoint(x: 0.568 * sx, y: 10.845 * sy),
                        control: CGPoint(x: -0.189 * sx, y: 9.5 * sy))
        // Bottom chevron
        p.addLine(to: CGPoint(x: 8.318 * sx, y: 18.443 * sy))
        p.addQuadCurve(to: CGPoint(x: 11.061 * sx, y: 15.754 * sy),
                        control: CGPoint(x: 10.304 * sx, y: 19.186 * sy))
        p.addLine(to: CGPoint(x: 6.617 * sx, y: 11.403 * sy))
        p.closeSubpath()
        return p
    }
}

/// Observes GCKSessionManager for Cast session start/end.
/// When a Cast session starts while video is playing, the app reloads the current
/// media onto the Cast device — same pattern used by YouTube, Netflix, etc.
