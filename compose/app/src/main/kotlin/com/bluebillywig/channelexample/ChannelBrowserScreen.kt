package com.bluebillywig.channelexample

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*

@Composable
fun ChannelBrowserScreen(
    onSelectChannel: (channelUrl: String, channelName: String, publicationHost: String) -> Unit,
    onOpenSettings: () -> Unit,
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("bbqa", android.content.Context.MODE_PRIVATE) }
    var activeTab by rememberSaveable { mutableStateOf(prefs.getString("active_publication", PUBLICATIONS[0].key) ?: PUBLICATIONS[0].key) }
    var search by rememberSaveable { mutableStateOf("") }
    var channels by remember { mutableStateOf<Map<String, List<ChannelItem>>>(emptyMap()) }
    var loading by remember { mutableStateOf(true) }
    var customPubs by remember { mutableStateOf<List<Publication>>(emptyList()) }

    // Persist active publication
    LaunchedEffect(activeTab) {
        prefs.edit().putString("active_publication", activeTab).apply()
    }
    var showAddInput by remember { mutableStateOf(false) }
    var addValue by remember { mutableStateOf("") }

    val allPubs = PUBLICATIONS + customPubs

    LaunchedEffect(allPubs) {
        loading = true
        channels = loadChannels(allPubs)
        loading = false
    }

    val tabChannels = channels[activeTab] ?: emptyList()
    val filtered = if (search.isBlank()) tabChannels
    else tabChannels.filter {
        it.name.contains(search, ignoreCase = true) || it.id.contains(search)
    }
    val activePub = allPubs.firstOrNull { it.key == activeTab } ?: allPubs[0]
    val accentColor = publicationColor(activeTab)

    Column(modifier = Modifier.fillMaxSize().background(Colors.background)) {
        HeaderView(title = "Channel SDK Example", subtitle = "Blue Billywig") {
            Text(
                "*",
                color = Colors.textLight,
                fontSize = FontSize.xl,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.clickable(onClick = onOpenSettings),
            )
        }

        // Publication tabs
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Colors.background)
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
        ) {
            allPubs.forEach { pub ->
                val isActive = pub.key == activeTab
                val color = publicationColor(pub.key)
                val count = channels[pub.key]?.size ?: 0
                Text(
                    text = "${pub.key} ($count)",
                    color = if (isActive) Colors.textLight else Colors.textMuted,
                    fontSize = FontSize.sm,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(9999.dp))
                        .background(if (isActive) color else Colors.surface)
                        .clickable { activeTab = pub.key; search = "" }
                        .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                )
            }
            if (showAddInput) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Spacing.xs)) {
                    BasicTextField(
                        value = addValue,
                        onValueChange = { addValue = it },
                        singleLine = true,
                        textStyle = LocalTextStyle.current.copy(color = Colors.text, fontSize = FontSize.sm),
                        cursorBrush = SolidColor(Colors.accent),
                        modifier = Modifier
                            .widthIn(min = 120.dp)
                            .clip(RoundedCornerShape(9999.dp))
                            .background(Colors.surface)
                            .padding(horizontal = Spacing.md, vertical = Spacing.xs),
                    )
                    Text("OK", color = Colors.textLight, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.clip(RoundedCornerShape(9999.dp)).background(Colors.accent)
                            .clickable {
                                val key = addValue.trim().lowercase()
                                if (key.isNotBlank() && allPubs.none { it.key == key }) {
                                    PUBLICATION_COLORS[key] = getAdHocColor()
                                    customPubs = customPubs + publicationFromKey(key)
                                    activeTab = key
                                }
                                showAddInput = false; addValue = ""
                            }
                            .padding(horizontal = Spacing.md, vertical = Spacing.xs))
                    Text("X", color = Colors.textMuted, modifier = Modifier.clickable { showAddInput = false; addValue = "" })
                }
            } else {
                Text(
                    "+",
                    color = Colors.textMuted,
                    fontSize = FontSize.lg,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(9999.dp))
                        .background(Colors.surface)
                        .clickable { showAddInput = true }
                        .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                )
            }
        }

        Divider(color = Colors.border, thickness = 1.dp)
        SearchBarView(value = search, onValueChange = { search = it })

        if (loading) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Colors.accent)
            }
        } else if (filtered.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    if (search.isBlank()) "No channels found" else "No channels match your filter",
                    color = Colors.textMuted,
                    fontSize = FontSize.md,
                )
            }
        } else {
            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(filtered, key = { "${activeTab}-${it.id}" }) { channel ->
                    ChannelCardView(
                        channel = channel,
                        accentColor = accentColor,
                        onPress = {
                            onSelectChannel(
                                getChannelUrl(activePub.host, channel.id),
                                channel.name,
                                activePub.host,
                            )
                        },
                    )
                }
            }
        }
    }
}

private suspend fun loadChannels(pubs: List<Publication>): Map<String, List<ChannelItem>> =
    withContext(Dispatchers.IO) {
        val json = Json { ignoreUnknownKeys = true; isLenient = true }
        pubs.associate { pub ->
            pub.key to try {
                val url = java.net.URL("https://${pub.host}/papi/search?className=Channel&limit=1000&sort=createddate+desc")
                val text = url.readText()
                val root = json.parseToJsonElement(text).jsonObject
                val items = root["items"]?.jsonArray ?: return@associate pub.key to emptyList()
                items.mapNotNull { el ->
                    try {
                        val obj = el.jsonObject
                        ChannelItem(
                            id = (obj["id"]?.jsonPrimitive?.contentOrNull ?: return@mapNotNull null),
                            name = obj["name"]?.jsonPrimitive?.contentOrNull ?: "Untitled",
                            status = obj["status"]?.jsonPrimitive?.contentOrNull ?: "",
                        )
                    } catch (_: Exception) { null }
                }
            } catch (e: Exception) {
                android.util.Log.e("ChannelBrowser", "Failed to load ${pub.key}: ${e.message}", e)
                emptyList()
            }
        }
    }

@Composable
fun SettingsScreen(onBack: () -> Unit) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val prefs = remember { context.getSharedPreferences("bb_channel_settings", android.content.Context.MODE_PRIVATE) }
    val json = remember { Json { ignoreUnknownKeys = true } }

    var settings by remember {
        mutableStateOf(
            try {
                json.decodeFromString<ChannelSettings>(prefs.getString("settings", null) ?: "")
            } catch (_: Exception) {
                ChannelSettings.DEFAULT
            }
        )
    }

    fun save(s: ChannelSettings) {
        settings = s
        prefs.edit().putString("settings", json.encodeToString(s)).apply()
    }

    Column(modifier = Modifier.fillMaxSize().background(Colors.background)) {
        HeaderView(title = "Settings", subtitle = "Global defaults", onBack = onBack)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(Spacing.xl),
        ) {
            // Environment picker
            Text("Environment", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(Spacing.xs))
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.xs)) {
                listOf("dev", "test", "acc", "prod").forEach { env ->
                    val active = settings.environment == env
                    Text(
                        text = env,
                        color = if (active) Colors.textLight else Colors.textMuted,
                        fontSize = FontSize.sm,
                        fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (active) Colors.accent else Colors.surface)
                            .clickable { save(settings.copy(environment = env)) }
                            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                    )
                }
            }
            Spacer(Modifier.height(Spacing.lg))

            // Display mode
            Text("Display mode", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(Spacing.xs))
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.xs)) {
                listOf("full", "embed").forEach { mode ->
                    val active = settings.displayMode == mode
                    Text(
                        text = mode,
                        color = if (active) Colors.textLight else Colors.textMuted,
                        fontSize = FontSize.sm,
                        fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (active) Colors.accent else Colors.surface)
                            .clickable { save(settings.copy(displayMode = mode)) }
                            .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                    )
                }
            }
            Spacer(Modifier.height(Spacing.lg))

            // Toggles
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("autoPlay", color = Colors.text, fontSize = FontSize.md, fontWeight = FontWeight.Medium)
                Switch(
                    checked = settings.autoPlay,
                    onCheckedChange = { save(settings.copy(autoPlay = it)) },
                    colors = SwitchDefaults.colors(checkedTrackColor = Colors.accent),
                )
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text("noStats", color = Colors.text, fontSize = FontSize.md, fontWeight = FontWeight.Medium)
                Switch(
                    checked = settings.noStats,
                    onCheckedChange = { save(settings.copy(noStats = it)) },
                    colors = SwitchDefaults.colors(checkedTrackColor = Colors.accent),
                )
            }
            Spacer(Modifier.height(Spacing.lg))

            // JWT
            Text("JWT", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(Spacing.xs))
            BasicTextField(
                value = settings.jwt,
                onValueChange = { save(settings.copy(jwt = it)) },
                singleLine = true,
                textStyle = LocalTextStyle.current.copy(color = Colors.text, fontSize = FontSize.xs),
                cursorBrush = SolidColor(Colors.accent),
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Colors.surface, RoundedCornerShape(8.dp))
                    .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            )
            Spacer(Modifier.height(Spacing.xxl))

            // Reset
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text(
                    "Reset to Defaults",
                    color = Colors.textLight,
                    fontSize = FontSize.md,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(9999.dp))
                        .background(Colors.error)
                        .clickable { save(ChannelSettings.DEFAULT) }
                        .padding(horizontal = Spacing.xl, vertical = Spacing.md),
                )
            }
        }
    }
}
