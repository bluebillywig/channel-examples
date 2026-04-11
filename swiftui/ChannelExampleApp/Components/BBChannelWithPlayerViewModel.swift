import SwiftUI
import BBNativePlayerKit_SwiftUI
import BBChannelSwiftUI
import os.log

private let log = Logger(subsystem: "com.bluebillywig.bbchannel", category: "BBChannelWithPlayer")

/// State holder for BBChannelWithPlayerView.
///
/// Equivalent to `BBChannelWithPlayerRef` in the React Native SDK.
/// Exposes both the channel VM (for navigation/player control) and native player state.
@MainActor
public class BBChannelWithPlayerViewModel: ObservableObject {
    /// The underlying channel ViewModel (navigation, auth, player control)
    public let channelVM = BBChannelViewModel()

    /// Native player state — not @Published to avoid unnecessary re-renders from player callbacks
    public var nativePlayerState = BBNativePlayerKit_SwiftUI.BBPlayerState()

    /// Whether the inline native player is currently visible
    @Published public var isPlayerVisible = false

    /// Current media info for the playing content
    @Published public var currentMedia: BBMediaInfo?

    /// Player lifecycle state
    @Published public var playerState: BBChannelPlayerState = .idle

    public init() {}

    // MARK: - Public API

    /// Dismiss and destroy the native player
    public func dismissNativePlayer() {
        nativePlayerState.pause()
        nativePlayerState.destroy()
        isPlayerVisible = false
        currentMedia = nil
        playerState = .idle
    }

    /// Hide player without destroying (for reuse on next detail page).
    /// Skips pause when casting — Cast playback should continue when navigating back.
    public func hidePlayer() {
        if !nativePlayerState.isCasting {
            nativePlayerState.pause()
        }
        isPlayerVisible = false
        playerState = .idle
    }

    /// Destroy player and release resources
    func destroyPlayer() {
        nativePlayerState.pause()
        nativePlayerState.destroy()
        isPlayerVisible = false
        currentMedia = nil
        playerState = .idle
    }
}

/// Native player lifecycle state
public enum BBChannelPlayerState: String, Sendable {
    case idle
    case loading
    case playing
    case paused
    case ended
}
