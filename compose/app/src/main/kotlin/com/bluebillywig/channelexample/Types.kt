package com.bluebillywig.channelexample

import kotlinx.serialization.Serializable

// Curated demo channels — replace with your own publication and channel IDs.

data class DemoChannel(
    val name: String,
    val url: String,
)

val DEMO_CHANNELS = listOf(
    DemoChannel("Demo Channel", "https://demo.bbvms.com/ch/1152.json"),
)

@Serializable
data class ChannelSettings(
    val autoPlay: Boolean = true,
    val noStats: Boolean = false,
    val jwt: String = "",
) {
    companion object {
        val DEFAULT = ChannelSettings()
    }
}

data class EventEntry(
    val id: Int,
    val time: String,
    val type: String,
    val category: EventCategory,
    val summary: String,
    val detail: String? = null,
)

enum class EventCategory { LIFECYCLE, NAVIGATION, PLAYER, ERROR, ANALYTICS }
