package com.bluebillywig.channelexample

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

@Composable
fun HeaderView(
    title: String,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    right: @Composable (() -> Unit)? = null,
) {
    val view = LocalView.current
    val density = LocalDensity.current
    val statusBarHeight = remember(view) {
        val insets = ViewCompat.getRootWindowInsets(view)
        val top = insets?.getInsets(WindowInsetsCompat.Type.statusBars())?.top ?: 0
        with(density) { top.toDp() }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Colors.dark)
            .padding(top = statusBarHeight + Spacing.md, bottom = Spacing.md, start = Spacing.lg, end = Spacing.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (onBack != null) {
            Text(
                text = "<",
                color = Colors.textLight,
                fontSize = FontSize.xl,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .clickable(onClick = onBack)
                    .padding(end = Spacing.md),
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(title, color = Colors.textLight, fontSize = FontSize.lg, fontWeight = FontWeight.Bold)
            if (!subtitle.isNullOrBlank()) {
                Text(subtitle, color = Colors.textMuted, fontSize = FontSize.xs, maxLines = 1)
            }
        }
        right?.invoke()
    }
}

@Composable
fun SearchBarView(value: String, onValueChange: (String) -> Unit) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = LocalTextStyle.current.copy(color = Colors.text, fontSize = FontSize.md),
        cursorBrush = SolidColor(Colors.accent),
        decorationBox = { inner ->
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.lg, vertical = Spacing.sm)
                    .background(Colors.surface, RoundedCornerShape(8.dp))
                    .padding(horizontal = Spacing.md, vertical = Spacing.sm),
            ) {
                if (value.isEmpty()) {
                    Text("Search channels...", color = Colors.textMuted, fontSize = FontSize.md)
                }
                inner()
            }
        },
    )
}

@Composable
fun ChannelCardView(
    channel: ChannelItem,
    accentColor: androidx.compose.ui.graphics.Color,
    onPress: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onPress)
            .padding(horizontal = Spacing.lg, vertical = Spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(accentColor),
        )
        Spacer(Modifier.width(Spacing.md))
        Column(modifier = Modifier.weight(1f)) {
            Text(channel.name, color = Colors.text, fontSize = FontSize.md, fontWeight = FontWeight.SemiBold)
            Text("ID: ${channel.id}", color = Colors.textMuted, fontSize = FontSize.xs)
        }
    }
}

@Composable
fun SettingsPanelView(
    settings: ChannelSettings,
    onChange: (ChannelSettings) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Colors.surface)
            .padding(Spacing.lg),
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
                        .background(if (active) Colors.accent else Colors.background)
                        .clickable { onChange(settings.copy(environment = env)) }
                        .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                )
            }
        }
        Spacer(Modifier.height(Spacing.md))

        // JWT
        Text("JWT", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(Spacing.xs))
        BasicTextField(
            value = settings.jwt,
            onValueChange = { onChange(settings.copy(jwt = it)) },
            singleLine = true,
            textStyle = LocalTextStyle.current.copy(color = Colors.text, fontSize = FontSize.xs),
            cursorBrush = SolidColor(Colors.accent),
            modifier = Modifier
                .fillMaxWidth()
                .background(Colors.background, RoundedCornerShape(8.dp))
                .padding(horizontal = Spacing.md, vertical = Spacing.sm),
        )
        Spacer(Modifier.height(Spacing.md))

        // Toggles
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text("autoPlay", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
            Switch(checked = settings.autoPlay, onCheckedChange = { onChange(settings.copy(autoPlay = it)) },
                colors = SwitchDefaults.colors(checkedTrackColor = Colors.accent))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text("noStats", color = Colors.textMuted, fontSize = FontSize.sm, fontWeight = FontWeight.SemiBold)
            Switch(checked = settings.noStats, onCheckedChange = { onChange(settings.copy(noStats = it)) },
                colors = SwitchDefaults.colors(checkedTrackColor = Colors.accent))
        }
    }
}

@Composable
fun EventInspectorView(events: List<EventEntry>, onClear: () -> Unit) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Colors.dark),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = !expanded }
                .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "Events (${events.size})",
                color = Colors.textLight,
                fontSize = FontSize.sm,
                fontWeight = FontWeight.SemiBold,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.md)) {
                Text(
                    "Clear",
                    color = Colors.accent,
                    fontSize = FontSize.sm,
                    modifier = Modifier.clickable(onClick = onClear),
                )
                Text(
                    if (expanded) "v" else "^",
                    color = Colors.textMuted,
                    fontSize = FontSize.sm,
                )
            }
        }

        if (expanded) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 200.dp)
                    .padding(horizontal = Spacing.lg),
            ) {
                events.take(50).forEach { event ->
                    val catColor = when (event.category) {
                        EventCategory.ERROR -> Colors.error
                        EventCategory.ANALYTICS -> Colors.accentSecondary
                        EventCategory.NAVIGATION -> Colors.accent
                        EventCategory.PLAYER -> Colors.success
                        EventCategory.LIFECYCLE -> Colors.textMuted
                    }
                    Text(
                        "${event.time} [${event.type}] ${event.summary}",
                        color = catColor,
                        fontSize = FontSize.xs,
                        maxLines = 1,
                        modifier = Modifier.padding(vertical = 1.dp),
                    )
                }
            }
        }
    }
}
