package com.bluebillywig.channelexample

import com.bluebillywig.bbchannel.compose.*
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import com.bluebillywig.bbnativeplayersdk.compose.BBPlayerState

/**
 * State holder for BBChannelWithPlayerView.
 *
 * Equivalent to `BBChannelWithPlayerRef` in the React Native SDK.
 * Exposes both the channel VM (for navigation/player control) and native player state.
 */
class BBChannelWithPlayerViewModel : ViewModel() {
    /** The underlying channel ViewModel (navigation, auth, player control) */
    val channelVM = BBChannelViewModel()

    /** Native player state (set by BBChannelWithPlayerView) */
    var nativePlayerState: BBPlayerState? = null

    /** Whether the inline native player is currently visible */
    var isPlayerVisible by mutableStateOf(false)

    /** Whether the current player is a modal overlay */
    var isModalPlayer by mutableStateOf(false)

    /** Current media info for the playing content */
    var currentMedia: BBMediaInfo? by mutableStateOf(null)

    /** Player lifecycle state */
    var playerState: BBChannelPlayerState by mutableStateOf(BBChannelPlayerState.IDLE)

    /** Dismiss and destroy the native player. Skips pause/destroy when casting. */
    fun dismissNativePlayer() {
        if (nativePlayerState?.isCasting != true) {
            nativePlayerState?.pause()
            nativePlayerState?.destroy()
        }
        isPlayerVisible = false
        isModalPlayer = false
        currentMedia = null
        playerState = BBChannelPlayerState.IDLE
    }

    /** Hide player without destroying (for reuse on next detail page).
     *  Skips pause when casting — Cast playback continues after back navigation. */
    fun hidePlayer() {
        if (nativePlayerState?.isCasting != true) {
            nativePlayerState?.pause()
        }
        isPlayerVisible = false
        playerState = BBChannelPlayerState.IDLE
    }

    /** Dismiss modal player */
    fun dismissModalPlayer(modalState: BBPlayerState? = null) {
        modalState?.pause()
        modalState?.destroy()
        isPlayerVisible = false
        isModalPlayer = false
        currentMedia = null
    }
}
