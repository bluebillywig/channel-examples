package com.bluebillywig.channelexample

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bluebillywig.bbchannel.compose.*
import androidx.lifecycle.viewmodel.compose.viewModel
import java.util.Calendar

private fun ts(): String {
    val c = Calendar.getInstance()
    return String.format(
        "%02d:%02d:%02d.%03d",
        c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE),
        c.get(Calendar.SECOND), c.get(Calendar.MILLISECOND),
    )
}

private fun categorize(type: String): EventCategory = when {
    type == "error" || type.contains("Error") -> EventCategory.ERROR
    type.startsWith("analytics") -> EventCategory.ANALYTICS
    type.contains("nav") || type.contains("Nav") || type == "canGoBack" -> EventCategory.NAVIGATION
    type.contains("player") || type.contains("Player") || type.contains("media") ||
        type.contains("Media") || type.contains("clip") || type.contains("Clip") ||
        type.contains("ad") || type == "timeUpdate" -> EventCategory.PLAYER
    else -> EventCategory.LIFECYCLE
}

@Composable
fun ChannelViewerScreen(
    channelUrl: String,
    channelName: String,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val globalSettings = remember {
        try {
            val prefs = context.getSharedPreferences("bb_channel_settings", android.content.Context.MODE_PRIVATE)
            val json = kotlinx.serialization.json.Json { ignoreUnknownKeys = true }
            json.decodeFromString<ChannelSettings>(prefs.getString("settings", null) ?: "")
        } catch (_: Exception) {
            ChannelSettings.DEFAULT
        }
    }
    var showSettings by remember { mutableStateOf(false) }
    var settings by remember { mutableStateOf(globalSettings) }
    var events by remember { mutableStateOf<List<EventEntry>>(emptyList()) }
    var eventIdCounter by remember { mutableIntStateOf(0) }
    var lastLoggedSecond by remember { mutableIntStateOf(-1) }

    val playerVM: BBChannelWithPlayerViewModel = viewModel()

    // Embed mode state
    var embedWidthPct by remember { mutableFloatStateOf(100f) }
    var embedHeightPct by remember { mutableFloatStateOf(50f) }
    var embedReloadKey by remember { mutableIntStateOf(0) }
    var embedAreaSize by remember { mutableStateOf(IntSize.Zero) }
    val density = LocalDensity.current

    val bundleUrl = getBundleUrl(settings.environment, settings.customBundleUrl)

    fun log(type: String, summary: String, detail: String? = null) {
        eventIdCounter++
        val entry = EventEntry(
            id = eventIdCounter, time = ts(), type = type,
            category = categorize(type), summary = summary, detail = detail,
        )
        events = (listOf(entry) + events).take(200)
    }

    val channelOptions = BBChannelOptions(
        autoPlay = settings.autoPlay,
        noStats = settings.noStats,
        jwt = settings.jwt.ifBlank { null },
        bundleUrl = bundleUrl,
    )

    val callbacks = BBChannelCallbacks(
        onReady = { log("ready", "Channel loaded") },
        onError = { e -> log("error", "[${e.code}] ${e.message}", "$e") },
        onNavigate = { e -> log("navigate", e.pageType, "$e") },
        onNavigationStateChange = { state ->
            log("navState", state.pageType.value, "$state")
        },
        onCanGoBackChange = { v -> log("canGoBack", "$v") },
        onSearch = { e -> log("search", "$e") },
        onMediaPlay = { m ->
            log("mediaPlay", "inline=${m.isInlinePlayer ?: false} block=${m.playerBlockId ?: "nil"} ${m.title ?: m.jsonUrl}", "$m")
        },
        onMediaPause = { m -> log("mediaPause", m.title ?: m.jsonUrl) },
        onMediaEnd = { m -> log("mediaEnd", m.title ?: m.jsonUrl) },
        onFirstPlayerMedia = { m -> log("firstPlayerMedia", m.title ?: m.jsonUrl, "$m") },
        onPlayerEvent = { e ->
            if (e.type != "timeupdate") log("playerEvent", e.type, "${e.data}")
        },
        onTimeUpdate = { e ->
            val sec = e.currentTime.toInt()
            if (sec % 10 == 0 && sec != lastLoggedSecond) {
                lastLoggedSecond = sec
                log("timeUpdate", "${sec}s / ${e.duration.toInt()}s")
            }
        },
        onClipLoaded = { e ->
            val raw = "${e.raw}"
            log("clipLoaded", raw.take(80), raw)
        },
        onAdStart = { e -> log("adStart", "${e.raw}") },
        onAdEnd = { e -> log("adEnd", "${e.raw}") },
        onPlayersChange = { p -> log("playersChange", "${p.size} players") },
        onActivePlayerChange = { id -> log("activePlayerChange", id ?: "none") },
        onAnalyticsEvent = { e ->
            val importantCodes = listOf("st", "fn", "xst", "xit", "xcl", "pa", "rs", "se", "pg")
            if (e.eventCode in importantCodes) {
                val props = "${e.properties}"
                log("analytics:${e.eventCode}", props.take(80), props)
            }
        },
        onExternalLink = { url -> log("externalLink", url) },
    )

    Column(modifier = Modifier.fillMaxSize().background(Colors.dark)) {
        // Header
        HeaderView(title = channelName, subtitle = channelUrl, onBack = onBack) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                // Open channel in browser
                Text(
                    "WEB",
                    color = Colors.textLight,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable {
                        val webUrl = channelUrl.replace(".json", ".html")
                        context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(webUrl)))
                    },
                )
                // Cast button — triggers player's showCastPicker
                Text(
                    "\uD83D\uDCF1", // cast icon placeholder
                    color = Colors.textLight,
                    fontSize = FontSize.lg,
                    modifier = Modifier.clickable { playerVM.nativePlayerState?.showCastPicker() },
                )
                Text(
                    "*",
                    color = if (showSettings) Colors.accent else Colors.textLight,
                    fontSize = FontSize.xl,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable { showSettings = !showSettings },
                )
            }
        }

        // Settings panel
        if (showSettings) {
            SettingsPanelView(settings = settings, onChange = { settings = it })
        }

        if (settings.displayMode == "embed") {
            // Embed mode: resizable channel with width/height sliders
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Colors.surface)
                    .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    Text("W ${embedWidthPct.toInt()}%", color = Colors.textMuted, fontSize = FontSize.xs, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.width(48.dp))
                    Slider(
                        value = embedWidthPct, onValueChange = { embedWidthPct = it },
                        valueRange = 20f..100f, steps = 79,
                        onValueChangeFinished = { embedReloadKey++ },
                        colors = SliderDefaults.colors(thumbColor = Colors.accent, activeTrackColor = Colors.accent),
                        modifier = Modifier.weight(1f),
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.sm)) {
                    Text("H ${embedHeightPct.toInt()}%", color = Colors.textMuted, fontSize = FontSize.xs, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.width(48.dp))
                    Slider(
                        value = embedHeightPct, onValueChange = { embedHeightPct = it },
                        valueRange = 10f..100f, steps = 89,
                        onValueChangeFinished = { embedReloadKey++ },
                        colors = SliderDefaults.colors(thumbColor = Colors.accent, activeTrackColor = Colors.accent),
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            // Embed area
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .onSizeChanged { embedAreaSize = it },
                contentAlignment = Alignment.TopStart,
            ) {
                val widthDp = with(density) { (embedAreaSize.width * embedWidthPct / 100f).toDp() }
                val heightDp = with(density) { (embedAreaSize.height * embedHeightPct / 100f).toDp() }

                key(embedReloadKey) {
                    BBChannelWithPlayerView(
                        channelUrl = channelUrl,
                        options = channelOptions,
                        viewModel = playerVM,
                        callbacks = callbacks,
                        modifier = Modifier.size(widthDp, heightDp),
                    )
                }
            }
        } else {
            // Full mode — BBChannelWithPlayerView handles everything
            BBChannelWithPlayerView(
                channelUrl = channelUrl,
                options = channelOptions,
                viewModel = playerVM,
                callbacks = callbacks,
                modifier = Modifier.weight(1f),
            )
        }

        // Event inspector
        EventInspectorView(events = events, onClear = { events = emptyList() })
    }
}
