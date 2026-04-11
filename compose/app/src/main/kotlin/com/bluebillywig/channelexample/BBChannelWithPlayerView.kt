package com.bluebillywig.channelexample

import com.bluebillywig.bbchannel.compose.*

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil.compose.AsyncImage
import com.bluebillywig.bbnativeplayersdk.compose.BBNativePlayer
import com.bluebillywig.bbnativeplayersdk.compose.BBPlayerOptions
import com.bluebillywig.bbnativeplayersdk.compose.rememberBBPlayerState
import kotlinx.coroutines.delay

/**
 * Composite composable combining BBChannelView with a native inline player.
 *
 * Equivalent to `BBChannelWithPlayer` in the React Native SDK.
 *
 * Usage:
 * ```kotlin
 * val playerVM: BBChannelWithPlayerViewModel = viewModel()
 *
 * BBChannelWithPlayerView(
 *     channelUrl = "https://demo.bbvms.com/ch/123.json",
 *     viewModel = playerVM,
 *     callbacks = BBChannelCallbacks(onReady = { println("Ready") })
 * )
 * ```
 */
@Composable
fun BBChannelWithPlayerView(
    channelUrl: String,
    options: BBChannelOptions = BBChannelOptions(),
    viewModel: BBChannelWithPlayerViewModel,
    callbacks: BBChannelCallbacks = BBChannelCallbacks(),
    showBackArrow: Boolean = true,
    playerAspectRatio: Float = 16f / 9f,
    modifier: Modifier = Modifier,
) {
    val nativePlayerState = rememberBBPlayerState()
    val modalPlayerState = rememberBBPlayerState()
    var containerWidthPx by remember { mutableIntStateOf(0) }
    val density = LocalDensity.current

    // Sync nativePlayerState to viewModel
    LaunchedEffect(nativePlayerState) {
        viewModel.nativePlayerState = nativePlayerState
    }

    // Merged options with nativePlayerMode enabled
    val mergedOptions = remember(options) {
        options.copy(nativePlayerMode = true)
    }

    // Deferred hide: cancel if detailPage arrives within 300ms
    var pendingHide by remember { mutableStateOf(false) }
    LaunchedEffect(pendingHide) {
        if (pendingHide) {
            delay(300)
            if (pendingHide && viewModel.isPlayerVisible) {
                viewModel.hidePlayer()
            }
            pendingHide = false
        }
    }

    fun handleMediaPlay(media: BBMediaInfo) {
        if (media.playerBlockId == "overviewPage") return

        // Modal playback: inline placeholder taps only. Detail page plays use inline.
        val shouldModal = media.isInlinePlayer == true
        if (shouldModal) {
            // Don't activate inline player for modal — prevents double playback
            if (viewModel.isPlayerVisible) {
                nativePlayerState.pause()
            }
            viewModel.currentMedia = media
            viewModel.isModalPlayer = true
            viewModel.isPlayerVisible = true
            return
        }

        val wasVisible = viewModel.isPlayerVisible
        val prevUrl = viewModel.currentMedia?.jsonUrl

        viewModel.currentMedia = media
        viewModel.isModalPlayer = false
        viewModel.isPlayerVisible = true

        if (prevUrl != media.jsonUrl) {
            val entityId = media.entityId
            val entityType = media.entityType ?: "mediaclip"
            val ctx = buildContext(media)
            if (entityId != null) {
                nativePlayerState.loadWithContentIdAndType(entityId, entityType, autoPlay = media.autoplay ?: true, context = ctx)
            } else {
                extractClipId(media.jsonUrl)?.let { clipId ->
                    nativePlayerState.loadWithContentIdAndType(clipId, "mediaclip", autoPlay = media.autoplay ?: true, context = ctx)
                }
            }
        } else if (wasVisible) {
            if (media.autoplay != false) {
                nativePlayerState.play()
            }
        }
    }

    fun handleNavigationStateChange(state: BBNavigationState) {
        if (viewModel.isPlayerVisible && state.pageType != BBPageType.DETAIL_PAGE) {
            pendingHide = true
        } else if (state.pageType == BBPageType.DETAIL_PAGE && pendingHide) {
            pendingHide = false
        }
    }

    fun handleDetailPageBack() {
        if (viewModel.isPlayerVisible) {
            viewModel.hidePlayer()
        }
        if (viewModel.channelVM.canGoBack) {
            viewModel.channelVM.goBack()
        } else {
            viewModel.channelVM.navigateTo("main")
        }
    }

    // Wrap user callbacks
    val wrappedCallbacks = remember(callbacks) {
        callbacks.copy(
            onMediaPlay = { media ->
                handleMediaPlay(media)
                callbacks.onMediaPlay?.invoke(media)
            },
            onNavigationStateChange = { state ->
                handleNavigationStateChange(state)
                callbacks.onNavigationStateChange?.invoke(state)
            },
        )
    }

    // Modal player dialog
    if (viewModel.isModalPlayer && viewModel.isPlayerVisible) {
        viewModel.currentMedia?.let { media ->
            Dialog(
                onDismissRequest = { viewModel.dismissModalPlayer(modalPlayerState) },
                properties = DialogProperties(usePlatformDefaultWidth = false),
            ) {
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.Black),
                    contentAlignment = Alignment.Center,
                ) {
                    BBNativePlayer(
                        jsonUrl = media.jsonUrl,
                        options = BBPlayerOptions(autoPlay = media.autoplay ?: true),
                        state = modalPlayerState,
                        modifier = Modifier.fillMaxWidth().aspectRatio(playerAspectRatio),
                    )
                    // Back arrow overlay
                    Text(
                        "<",
                        color = Color.White,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier
                            .align(Alignment.TopStart)
                            .padding(top = 48.dp, start = 16.dp)
                            .background(Color.Black.copy(alpha = 0.4f))
                            .clickable { viewModel.dismissModalPlayer(modalPlayerState) }
                            .padding(16.dp),
                    )
                }
            }
        }
    }

    // Hardware back handler
    BackHandler(enabled = true) {
        if (viewModel.isModalPlayer && viewModel.isPlayerVisible) {
            viewModel.dismissModalPlayer(modalPlayerState)
        } else if (viewModel.isPlayerVisible) {
            handleDetailPageBack()
        } else if (viewModel.channelVM.canGoBack) {
            viewModel.channelVM.goBack()
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .onSizeChanged { containerWidthPx = it.width },
    ) {
        // Back arrow header
        if (showBackArrow && viewModel.isPlayerVisible && !viewModel.isModalPlayer) {
            viewModel.currentMedia?.let { media ->
                val bgColor = parseHexColor(media.backgroundColor ?: "#000")
                val bgImageUrl = media.blurredThumbnailUrl ?: media.thumbnailUrl
                val showBg = media.showThumbnailAsBackground == true && bgImageUrl != null

                val textColor = parseHexColor(media.textColor ?: "#fff")
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(bgColor),
                    contentAlignment = Alignment.CenterStart,
                ) {
                    if (showBg && bgImageUrl != null) {
                        AsyncImage(
                            model = bgImageUrl,
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxSize().blur(15.dp),
                        )
                        Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.55f)))
                    }
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    ) {
                        // Back arrow matching web channel backArrow.svg / RN SDK
                        Canvas(
                            modifier = Modifier
                                .size(width = 24.dp, height = 16.dp)
                                .clickable { handleDetailPageBack() }
                                .padding(4.dp),
                        ) {
                            val sx = size.width / 31f
                            val sy = size.height / 20f
                            val path = androidx.compose.ui.graphics.Path().apply {
                                moveTo(6.617f * sx, 11.403f * sy)
                                lineTo(29.062f * sx, 11.403f * sy)
                                quadraticBezierTo(31f * sx, 9.503f * sy, 29.062f * sx, 7.603f * sy)
                                lineTo(6.617f * sx, 7.603f * sy)
                                lineTo(11.061f * sx, 3.246f * sy)
                                quadraticBezierTo(11.818f * sx, 1.299f * sy, 8.318f * sx, 0.557f * sy)
                                quadraticBezierTo(7.561f * sx, -0.186f * sy, 0.568f * sx, 8.155f * sy)
                                quadraticBezierTo(-0.189f * sx, 9.5f * sy, 0.568f * sx, 10.845f * sy)
                                lineTo(8.318f * sx, 18.443f * sy)
                                quadraticBezierTo(10.304f * sx, 19.186f * sy, 11.061f * sx, 15.754f * sy)
                                lineTo(6.617f * sx, 11.403f * sy)
                                close()
                            }
                            drawPath(path, color = textColor)
                        }
                    }
                }
            }
        }

        // Inline player
        val inlineMedia = viewModel.currentMedia?.takeIf { !viewModel.isModalPlayer }
        if (inlineMedia != null) {
            val isShown = viewModel.isPlayerVisible
            val computedHeightDp = if (containerWidthPx > 0) {
                with(density) { (containerWidthPx / playerAspectRatio).toDp() }
            } else {
                0.dp
            }

            BBNativePlayer(
                jsonUrl = inlineMedia.jsonUrl,
                options = BBPlayerOptions(autoPlay = inlineMedia.autoplay ?: true),
                state = nativePlayerState,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(if (isShown) computedHeightDp else 0.dp)
                    .background(Color.Black),
            )
        }

        // Channel WebView
        BBChannelView(
            channelUrl = channelUrl,
            options = mergedOptions,
            viewModel = viewModel.channelVM,
            callbacks = wrappedCallbacks,
            modifier = Modifier.weight(1f),
        )
    }

    DisposableEffect(Unit) {
        onDispose {
            nativePlayerState.pause()
            nativePlayerState.destroy()
        }
    }
}

private fun buildContext(media: BBMediaInfo): Map<String, Any?>? {
    val collectionId = media.contextCollectionId ?: return null
    return buildMap {
        put("contextCollectionType", media.contextCollectionType ?: "MediaClipList")
        put("contextCollectionId", collectionId)
        media.contextEntityType?.let { put("contextEntityType", it) }
        media.contextEntityId?.let { put("contextEntityId", it) }
        media.listIndex?.let { put("listIndex", it) }
    }
}

private fun extractClipId(jsonUrl: String): String? {
    val idx = jsonUrl.indexOf("/c/")
    if (idx < 0) return null
    val after = jsonUrl.substring(idx + 3)
    val dotIdx = after.indexOf(".json")
    if (dotIdx < 0) return null
    return after.substring(0, dotIdx)
}

private fun parseHexColor(hex: String): Color {
    val clean = hex.trimStart('#')
    return try {
        Color(android.graphics.Color.parseColor("#$clean"))
    } catch (_: Exception) {
        Color.Black
    }
}
